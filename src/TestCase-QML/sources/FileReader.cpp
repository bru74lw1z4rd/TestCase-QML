#include "include/FileReader.h"

FileReader::FileReader(QObject* parent)
    : QObject { parent }
    , m_wordRegularExpression(QString("[\\p{L}]{%1,}").arg(minimumWordLength))
{
}

///
/// \brief FileReader::prepareFile - Функция проверяет файл и готовит его к дальнейшей обработке.
/// \param filePath - Путь к файлу в системе.
///
void FileReader::prepareFile(QString filePath)
{
    if (!filePath.startsWith(androidUri) && QUrl(filePath).isLocalFile()) {
        filePath = QUrl(filePath).toLocalFile();
    }

    QFileInfo fileInfo(filePath);
    if ((fileInfo.exists(filePath) || fileInfo.isReadable())) {
        m_filePath = filePath;

        /* Обнуляем значеняи при подготовке */
        m_canceled = false;
        m_currentProgress = 0;
        m_totalFileLength = 0;
        m_wordsList.clear();
        m_wordsDictionary.clear();

        /*
         * Считываем количество символов в тексте,
         * это понадобится для progress бара.
         */
        static_cast<void>(QtConcurrent::run(&m_workThreadPool, [&]() {
            QFile file(m_filePath);
            if (file.open(QIODevice::ReadOnly)) {
                if (file.size() > QString::fromUtf8(file.read(minimumWordLength)).size()) {
                    emit prepareFileChanged();
                } else {
                    emit errorOccured(FileReaderError::PreparingFileError, "Empty file");
                }

                /* Подсчитываем общее кол-во слов */
                QRegularExpressionMatchIterator iterator = m_wordRegularExpression.globalMatch(QString::fromUtf8(file.readAll()).simplified());

                while (iterator.hasNext()) {
                    iterator.next();

                    m_totalFileLength += 1;
                }

                setTotalFileLength(m_totalFileLength);
            }
        }));
    } else {
        emit errorOccured(FileReaderError::PreparingFileError, "Uknown Error");
    }
}

///
/// \brief FileReader::startWork - Функция запускает работу по считыванию слов в файле.
///
void FileReader::startWork()
{
    /* Устанавливаем флаг, что на данный момент выполняется работа */
    setRunning(true);

    static_cast<void>(QtConcurrent::run(&m_workThreadPool, [&]() {
        QFile file(m_filePath);
        if (file.open(QIODevice::ReadOnly)) {
            QRegularExpressionMatchIterator iterator = m_wordRegularExpression.globalMatch(QString::fromUtf8(file.readAll()).simplified());

            while (iterator.hasNext()) {
                /* Каждое исполнение, проверяем, поставил ли пользователь паузу */
                m_workThreadMutex.lock();

                if (m_canceled == true) {
                    /*
                     * Перед уничтожением потока, требуестя обязательно разблокировать mutex.
                     * Так же это понадобится для обновления UI.
                     */
                    m_workThreadMutex.unlock();

                    emit workCanceledChanged();

                    return;
                }

                while (getPause() && m_canceled == false) {
                    m_workThreadWaitCondition.wait(&m_workThreadMutex);
                }

                m_workThreadMutex.unlock();

                /* Обрабатываем каждый match */
                QRegularExpressionMatch match = iterator.next();
                if (match.hasMatch()) {
                    /*
                     * Передаем каждое найденное слово в QML
                     * это нужно для динамического отображения найденных слов.
                     */

                    if (!match.captured(0).isEmpty()) {
                        /* Вставляет данные в словарь для подсчета */
                        m_wordsDictionary.insert(match.captured(), m_wordsDictionary.value(match.captured()) + 1);

                        /*
                         * Т.к. QHash не сортируется, требуется создать QList,
                         * который будет отсортирован, данные операции с QList значительно замедляют код,
                         * но делают UI более живым.
                         */
                        QList<QPair<QString, quint32>>::Iterator searchIterator = std::find_if(m_wordsList.begin(), m_wordsList.end(), [match](const QPair<QString, quint32>& firstValue) {
                            return firstValue.first == match.captured();
                        });

                        if (searchIterator != m_wordsList.end()) {
                            searchIterator->second = m_wordsDictionary.value(match.captured());
                        } else {
                            m_wordsList.append(QPair<QString, quint32>(match.captured(), m_wordsDictionary.value(match.captured())));
                        }

                        /*  Обновляем текущий прогресс */
                        if (m_currentProgress + 1 < m_totalFileLength) {
                            setCurrentProgress(m_currentProgress + 1);
                        }
                    }
                }
            }

            /* Сортируем полученные значения по value */
            std::sort(m_wordsList.begin(), m_wordsList.end(), [](const QPair<QString, quint32>& firstValue, const QPair<QString, quint32>& secondValue) {
                return firstValue.second > secondValue.second;
            });

            /*
             * Чтобы избежать непредвиденных обстоятельств,
             * устанавилваем максимумальный прогресс.
             */
            setCurrentProgress(m_totalFileLength);

            setRunning(false);
        } else {
            emit errorOccured(FileReaderError::OpenError, file.errorString());
        }
    }));
}

///
/// \brief FileReader::getLastMostUsableWords - Функция получает топ используемых слов в словаре
/// \param count - Количество слов, которое будет получено.
///
void FileReader::getLastMostUsableWords()
{
    if (!m_mostUsableWordsRequested) {
        static_cast<void>(QtConcurrent::run(&m_workThreadPool, [&]() {
            /* Помечаем, что пользовательский запрос на получение уже обрабатывается */
            m_mostUsableWordsRequested = true;

            QMutexLocker locker(&m_wordsListMutext);

            QList<QVariantList> words;

            /* Сортируем лист, только если в этот момент у нас запущена обработка */
            if ((m_currentProgress != 0 && m_totalFileLength != 0) && (m_currentProgress != m_totalFileLength)) {
                QList<QPair<QString, quint32>> tempDictionary = m_wordsList;

                /* Сортируем элементы, т.к. новые элементы не отсортированы */
                std::sort(tempDictionary.begin(), tempDictionary.end(), [](const QPair<QString, quint32>& firstValue, const QPair<QString, quint32>& secondValue) {
                    return firstValue.second > secondValue.second;
                });

                for (quint16 i = 0; i < maxChartBarsCount; ++i) {
                    /* Проверяем на количество возможных слов */
                    if (i < tempDictionary.size() && tempDictionary.size() != 0) {
                        /* Создаем читабельный для QML формат */
                        QVariantList data;
                        data.append(tempDictionary.at(i).first);
                        data.append(tempDictionary.at(i).second);

                        /* Добавляем слово в локальный словрь */
                        words.append(data);
                    }
                }
            } else {
                for (quint16 i = 0; i < maxChartBarsCount; ++i) {
                    /* Проверяем на количество возможных слов */
                    if (i < m_wordsList.size() && m_wordsList.size() != 0) {
                        /* Создаем читабельный для QML формат */
                        QVariantList data;
                        data.append(m_wordsList.at(i).first);
                        data.append(m_wordsList.at(i).second);

                        /* Добавляем слово в локальный словрь */
                        words.append(data);
                    }
                }
            }

            /* Передаем значенияв QML */
            emit mostUsableWordsChanged(words);

            m_mostUsableWordsRequested = false;
        }));
    }
}

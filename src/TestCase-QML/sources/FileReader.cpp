#include "include/FileReader.h"

FileReader::FileReader(QObject* parent)
    : QObject { parent }
    , m_wordRegularExpression(QString("[\\p{L}]{%1,}").arg(minimumWordLength))
{
}

///
/// \brief FileReader::prepareFile - Функция проверяет файл и готовит его к дальнейшей обработке.
/// \param filePath - Путь к файлу в системе.
/// \return Возвращает 'true', если удалось подготовить файл для дальнейшего чтения и 'false' при ошибке.
///
bool FileReader::prepareFile(QString filePath)
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
        m_dictionary.clear();

        QFile file(filePath);
        if (file.open(QIODevice::ReadOnly)) {
            /*
             * Считываем количество символов в тексте,
             * это понадобится для progress бара.
             */
            QFuture<qsizetype> result = QtConcurrent::run(&m_workThreadPool, [&]() {
                return QString::fromUtf8(file.readAll()).simplified().size();
            });

            if (result.result() != 0) {
                setTotalFileLength(result.result());

                return true;
            }
        }
    }

    return false;
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
                        /* Добавляем новое слово в словарь */
                        m_dictionary.append(QPair<QString, quint32>(match.captured(0), match.captured(0).size()));

                        /* Обновляем текущий прогресс */
                        setCurrentProgress(m_currentProgress + match.captured(0).size());
                    }
                }
            }

            /*
             * Отключаем возможность паузы и остановки в самом конце процесса подсчета слов,
             * т.к. это опасно и банально бесполезно
             */
            emit disableCanceling();

            /* Сортируем полученные значения по value */
            std::sort(m_dictionary.begin(), m_dictionary.end(), [](const QPair<QString, quint32>& firstValue, const QPair<QString, quint32>& secondValue) {
                return firstValue.second > secondValue.second;
            });

            /*
             * Т.к. точно и линейно подсчитывать слишком дорого и долго, то
             * когда все действия были выполнены, устанавливаем макисимум в progress bar
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

            QList<QVariantList> words;

            /* Сортируем лист, только если в этот момент у нас запущена обработка */
            if ((m_currentProgress != 0 && m_totalFileLength != 0) && (m_currentProgress != m_totalFileLength)) {
                QList<QPair<QString, quint32>> tempDictionary = m_dictionary;

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
                    if (i < m_dictionary.size() && m_dictionary.size() != 0) {
                        /* Создаем читабельный для QML формат */
                        QVariantList data;
                        data.append(m_dictionary.at(i).first);
                        data.append(m_dictionary.at(i).second);

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

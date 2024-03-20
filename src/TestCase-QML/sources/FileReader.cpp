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

        QFile file(filePath);
        if (file.open(QIODevice::ReadOnly)) {
            /*
             * Считываем количество символов в тексте,
             * это понадобится для progress бара.
             */
            QFuture<qsizetype> result = QtConcurrent::run(&m_workThreadPool, [&]() {
                return QString::fromUtf8(file.readAll()).simplified().size();
            });

            setTotalFileLength(result.result());

            return true;
        }
    }

    return false;
}

///
/// \brief FileReader::startWork - Функция запускает работу по считыванию слов в файле.
///
void FileReader::startWork()
{
    static_cast<void>(QtConcurrent::run(&m_workThreadPool, [&]() {
        QFile file(m_filePath);
        if (file.open(QIODevice::ReadOnly)) {
            QTextStream textStream(&file);

            while (!textStream.atEnd()) {
                /* Каждое исполнение, проверяем, поставил ли пользователь паузу */
                m_workThreadMutex.lock();

                if (m_canceled == true) {
                    /*
                     * Перед уничтожением потока, требуестя обязательно разблокировать mutex.
                     * Так же это понадобится для обновления UI.
                     */
                    m_workThreadMutex.unlock();

                    emit workCanceledChanged();

                    break;
                }

                while (getPause() && m_canceled == false) {
                    m_workThreadWaitCondition.wait(&m_workThreadMutex);
                }

                m_workThreadMutex.unlock();

                /* Начинаем поиск слов с помощью выбранного метода поиска */
                const QString currentLine = textStream.readLine().simplified();

                QRegularExpressionMatchIterator iterator = m_wordRegularExpression.globalMatch(currentLine);
                while (iterator.hasNext()) {
                    QRegularExpressionMatch match = iterator.next();
                    if (match.hasMatch()) {
                        /*
                         * Передаем каждое найденное слово в QML
                         * это нужно для динамического отображения найденных слов.
                         */
                        emit newWordFoundChanged(match.captured(0));
                    }
                }

                if (!currentLine.isEmpty()) {
                    /* Если у нас имеется новая строка, добавляем +1 */
                    if (!textStream.atEnd()) {
                        m_currentProgress += 1;
                    }

                    setCurrentProgress(m_currentProgress + currentLine.size());
                }
            }
        } else {
            emit errorOccured(FileReaderError::OpenError, file.errorString());
        }
    }));
}

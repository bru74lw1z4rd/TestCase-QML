#include "include/FileReader.h"

FileReader::FileReader(QObject* parent)
    : QObject { parent }
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

        /*
         * Считываем количество символов в тексте,
         * это понадобится для progress бара.
         *
         * Т.к. у нас текстовый файл, то размер файла будет = количеству символов.
         */
        setTotalFileLength(fileInfo.size());

        return true;
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
                const QStringList words = textStream.readLine().split(splitSymbol);

                for (const QString& word : words) {
                    if (word.length() > minimumWordLength) {
                        /*
                         * Передаем каждое найденное слово в QML
                         * это нужно для динамического отображения найденных слов.
                         */
                        emit newWordFoundChanged(word);
                    }

                    /* Добавляем размер 'splitSymbol', т.к. до этого мы удаляли этот символ из текста */
                    setCurrentProgress(m_currentProgress + word.length() + splitSymbol.size());
                }

                // QThread::msleep(500); /// DEBUG
            }
        } else {
            qDebug() << file.errorString() << m_filePath;

            emit errorOccured(FileReaderError::OpenError, file.errorString());
        }
    }));
}

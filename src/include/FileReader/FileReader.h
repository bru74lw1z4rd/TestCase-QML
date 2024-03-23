#ifndef FILEREADER_H
#define FILEREADER_H

#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QFuture>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <QRegularExpression>
#include <QTextStream>
#include <QThreadPool>
#include <QUrl>
#include <QtConcurrent>

///
/// \brief The FileReader class - Класс занимается обработкой файлов и подсчитыванием слов в этих файлах.
///
class FileReader : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool paused READ getPause WRITE setPause NOTIFY pauseChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(quint64 currentProgress READ currentProgress NOTIFY currentProgressChanged)
    Q_PROPERTY(quint64 totalFileLength READ totalFileLength NOTIFY totalFileLengthChanged)

#define androidUri "content:"
#define maxThreadCount 1
#define minimumWordLength 3
#define maxChartBarsCount 15

#define initializeFileReaderErrors qmlRegisterUncreatableType<FileReader>("FileReader.FileReaderError", 1, 0, "FileReaderError", "Cannot initialize FileReaderError in QML");

public:
    explicit FileReader(QObject* parent = nullptr);
    ~FileReader()
    {
        m_canceled = true;
    }

    enum class FileReaderError {
        NoError = 0,
        OpenError = 1,
        PreparingFileError = 2,
        ReadingError = 3
    };
    Q_ENUM(FileReaderError)

    /*********/
    /* pause */
    /*********/

    [[nodiscard]] inline bool getPause() const
    {
        return m_paused;
    }

    inline void setPause(const bool paused)
    {
        /* Блокируем mutex, чтобы избежать проблем с синхронизацией */
        QMutexLocker locker(&m_workThreadMutex);

        m_paused = paused;

        /* Если пользователь продолжил исполнение */
        if (m_paused == false && m_canceled == false) {
            m_workThreadWaitCondition.wakeAll();
        }

        emit pauseChanged();
    }

    /***********/
    /* running */
    /***********/

    [[nodiscard]] inline bool running() const
    {
        return m_running;
    }

    inline void setRunning(const bool running)
    {
        m_running = running;
        emit runningChanged();
    }

    /*******************/
    /* currentProgress */
    /*******************/

    [[nodiscard]] inline quint64 currentProgress() const
    {
        return m_currentProgress;
    }

    inline void setCurrentProgress(const quint64 currentProgress)
    {
        m_currentProgress = currentProgress;
        emit currentProgressChanged();
    }

    /*******************/
    /* totalFileLength */
    /*******************/

    [[nodiscard]] inline quint64 totalFileLength() const
    {
        return m_totalFileLength;
    }

    inline void setTotalFileLength(const quint64 totalFileLength)
    {
        m_totalFileLength = totalFileLength;
        emit totalFileLengthChanged();
    }

public slots:
    ///
    /// \brief prepareFile - Функция подготавливает файл к дальнейшей обработке.
    /// \param filePath - Путь к файлу в системе.
    ///
    void prepareFile(QString filePath);

    ///
    /// \brief startWork - Функция запускает работу по считыванию слов в файле.
    ///
    void startWork();

    ///
    /// \brief getLastMostUsableWords - Функция получает топ используемых слов в словаре
    /// \param count - Количество слов, которое будет получено.
    ///
    void getLastMostUsableWords();

    ///
    /// \brief cancel - Функция отменяет запланированную работу с файлом.
    ///
    inline void cancel()
    {
        m_canceled = true;

        m_wordsList.clear();
    }

    ///
    /// \brief pause - Функция ставит на паузу обработку файла. Функция создана для удобства
    ///
    inline void pause()
    {
        setPause(true);
    }

    ///
    /// \brief resume - Функция возобновляет обработку файла. Функция создана для удобства
    ///
    inline void resume()
    {
        setPause(false);
    }

signals:
    void disableCanceling();
    void prepareFileChanged();
    void errorOccured(const FileReaderError error, const QString& reason);
    void mostUsableWordsChanged(const QList<QVariantList>& words);
    void newWordFoundChanged(const QString& word);
    void workCanceledChanged();

    void pauseChanged();
    void runningChanged();
    void currentProgressChanged();
    void totalFileLengthChanged();

private:
    /*******/
    /* QML */
    /*******/

    bool m_running = false;
    bool m_paused = false;
    bool m_canceled = false;
    bool m_mostUsableWordsRequested = false;
    quint64 m_currentProgress = 0;
    quint64 m_totalFileLength = 0;
    QString m_filePath;

    /**********/
    /* Worker */
    /**********/

    QMutex m_workThreadMutex;
    QWaitCondition m_workThreadWaitCondition;
    QThreadPool m_workThreadPool;

    QHash<QString, quint32> m_wordsDictionary;
    QList<QPair<QString, quint32>> m_wordsList;

    const QStringList acceptableFileFormats { "txt" };
    const QRegularExpression m_wordRegularExpression;
};

Q_DECLARE_METATYPE(FileReader::FileReaderError)

#endif // FILEREADER_H

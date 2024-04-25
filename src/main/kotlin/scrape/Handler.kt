package scrape


import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.RequestHandler
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.newSingleThreadContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.jsoup.Jsoup
import org.jsoup.select.Elements
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipFile
import java.sql.Connection
import java.sql.DriverManager
import java.sql.SQLException

private fun getDbConnection(): Connection {
    val dbHost = System.getenv("DB_HOST")
    val dbUser = System.getenv("DB_USER")
    val dbPass = System.getenv("DB_PASS")
    val dbUrl = "jdbc:postgresql://$dbHost/bookshelf"

    return DriverManager.getConnection(dbUrl, dbUser, dbPass)
}


data class BookMetadata(
    val title: String?,
    val author: String?,
    val language: String?
)
val dbDispatcher = newSingleThreadContext("DBDispatcher")

class Handler : RequestHandler<ScheduledEvent, String> {

    override fun handleRequest(input: ScheduledEvent, context: Context): String  {
        val logger = context.logger
        logger.log("Starting scheduled task...")

        scrape(context)

        logger.log("Task completed successfully.")
        return "Success"
    }
}
fun scrape(context: Context) = runBlocking {
    val client = OkHttpClient()
    val doc = Jsoup.connect("https://www.gutenberg.org/robot/harvest?filetypes[]=txt").get()
    val links: Elements = doc.select("a")
    links.forEach { link ->
        launch(Dispatchers.IO){
            downloadUnzipSend(client, link.attr("href"), context)
        }
    }

}


suspend fun downloadUnzipSend(client: OkHttpClient, zipURL: String, context: Context) = coroutineScope{
    if (zipURL.take(4) != "http"){
        return@coroutineScope
    }
    try {

        val zipFile = downloadZip(client, zipURL)
        val bookTxt = unzipBook(zipFile)
        bookTxt?.let {
            val bootMetadata = extractMetadata(it)
            context.logger.log("Extracted for ${bootMetadata.title}\n${bootMetadata.author}\n${bootMetadata.language}")
            withContext(dbDispatcher) {
                insertBook(bootMetadata,context)
            }
        }
    } catch (e:Exception){
        context.logger.log("Error processing $zipURL: ${e.message}")
    }
}

fun unzipBook(zipFile: File): File? {
    ZipFile(zipFile).use { zip ->
        zip.entries().asSequence().forEach { entry ->
            if (!entry.isDirectory && entry.name.endsWith(".txt")) {
                val outputFile = File(zipFile.parentFile, entry.name)
                zip.getInputStream(entry).use { input ->
                    outputFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                return outputFile  // Return the first .txt file found
            }
        }
    }
    return null  // Return null if no .txt file found
}

fun downloadZip(client: OkHttpClient, zipURL: String): File{
    val request = Request.Builder()
        .url(zipURL)
        .build()

    client.newCall(request).execute().use {   response  ->
        if (!response.isSuccessful) throw IOException("Unexpected code $response")

        // Create the tmp directory if it doesn't exist
        val tmpDir = File("/tmp")
        if (!tmpDir.exists()) tmpDir.mkdirs()

        // Define the file name from URL and create a file output stream to write the downloaded file
        val fileName = zipURL.substring(zipURL.lastIndexOf('/') + 1)
        val fileOutput = File(tmpDir, fileName)
        val fos = FileOutputStream(fileOutput)
        response.body?.byteStream()?.use { inputStream ->
            fos.use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
        return fileOutput
    }

}
fun extractMetadata(bookFile: File): BookMetadata {
    val titleRegex = Regex("Title: (.+)")
    val authorRegex = Regex("Author: (.+)")
    val languageRegex = Regex("Language: (.+)")

    var title: String? = null
    var author: String? = null
    var language: String? = null

    bookFile.useLines { lines ->
        lines.forEach { line ->
            if (title == null && line.contains("Title:")) {
                title = titleRegex.find(line)?.groupValues?.get(1)
            }
            if (author == null && line.contains("Author:")) {
                author = authorRegex.find(line)?.groupValues?.get(1)
            }
            if (language == null && line.contains("Language:")) {
                language = languageRegex.find(line)?.groupValues?.get(1)
            }
            if (line.startsWith("***")) return@useLines
        }
    }

    return BookMetadata(title, author, language)
}
suspend fun insertBook(bookMetaData: BookMetadata, context: Context) = withContext(dbDispatcher) {
    val logger = context.logger
    val dbConnection: Connection by lazy { getDbConnection() }

    val sql = "INSERT INTO books (title, author, language) VALUES (?, ?, ?)"
    try {
        dbConnection.prepareStatement(sql).use { statement ->
            statement.setString(1, bookMetaData.title)
            statement.setString(2, bookMetaData.author)
            statement.setString(3, bookMetaData.language)

            statement.executeUpdate()
        }
        logger.log("INSERTED: ${bookMetaData.title}")
    } catch (e: SQLException) {
        logger.log("Error inserting book data: ${e.message}")
    }
}

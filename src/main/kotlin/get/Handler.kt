package get

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.RequestHandler
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse
import com.google.gson.Gson
import java.sql.Connection
import java.sql.DriverManager
import java.sql.SQLException

class Handler : RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse> {

    private fun getDbConnection(): Connection {
        val dbHost = System.getenv("DB_HOST")
        val dbUser = System.getenv("DB_USER")
        val dbPass = System.getenv("DB_PASS")
        val dbUrl = "jdbc:postgresql://$dbHost/bookshelf"
        return DriverManager.getConnection(dbUrl, dbUser, dbPass)
    }

    override fun handleRequest(input: APIGatewayV2HTTPEvent, context: Context): APIGatewayV2HTTPResponse {
        val gson = Gson()
        var responseBody = ""

        try {
            getDbConnection().use { conn ->
                val stmt = conn.createStatement()
                val rs = stmt.executeQuery("SELECT * FROM books")
                val books = mutableListOf<Map<String, Any>>()
                while (rs.next()) {
                    val book = mapOf(
                        "id" to rs.getInt("id"),
                        "createdAt" to rs.getTimestamp("createdAt").toString(),
                        "title" to rs.getString("title"),
                        "author" to rs.getString("author"),
                        "language" to rs.getString("language")
                    )
                    books.add(book)
                }
                responseBody = gson.toJson(mapOf("Books" to books))
            }
        } catch (e: SQLException) {
            responseBody = gson.toJson(mapOf("message" to "Failed to connect to database: ${e.message}"))
            return APIGatewayV2HTTPResponse().apply {
                statusCode = 500
                headers = mapOf("Content-Type" to "application/json")
                body = responseBody
            }
        }

        return APIGatewayV2HTTPResponse().apply {
            statusCode = 200
            headers = mapOf("Content-Type" to "application/json")
            body = responseBody
        }
    }
}

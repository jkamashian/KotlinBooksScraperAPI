package get

import com.amazonaws.services.lambda.runtime.Context
import com.amazonaws.services.lambda.runtime.RequestHandler
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse
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
        var responseMessage = "Hello World!"
        try {
            getDbConnection().use { conn ->
                val stmt = conn.createStatement()
                val rs = stmt.executeQuery("SELECT NOW()")
                if (rs.next()) {
                    responseMessage = "Database time is: ${rs.getString(1)}"
                }
            }
        } catch (e: SQLException) {
            responseMessage = "Failed to connect to database: ${e.message}"
        }

        return APIGatewayV2HTTPResponse().apply {
            statusCode = 200
            headers = mapOf("Content-Type" to "application/json")
            body = """{"message": "$responseMessage"}"""
        }
    }
}

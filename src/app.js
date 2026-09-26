import express from "express"
import { errorHandler } from "./middlewares/error-handler.middleware.js"

const app = express()

app.use(express.json())

app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    data: new Date(),
    message: "헬스체크",
  })
})

app.use(errorHandler)

export default app

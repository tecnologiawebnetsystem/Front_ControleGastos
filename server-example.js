const express = require("express")
const cors = require("cors")
const app = express()

// Habilitar CORS para todas as origens
app.use(cors())

// Ou para configuração mais específica:
app.use(
  cors({
    origin: "*", // Ou especifique origens permitidas: ['http://localhost:3000', 'https://seu-app.com']
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
)

// Suas rotas e lógica do servidor aqui
app.post("/api/auth/login", (req, res) => {
  // Lógica de autenticação
})

app.listen(3000, "0.0.0.0", () => {
  console.log("Servidor rodando na porta 3000")
})


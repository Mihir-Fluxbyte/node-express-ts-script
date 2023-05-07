#!/bin/bash

read -p "Enter the project name: " project_name

# Check if the project name is not empty
if [ -z "$project_name" ]; then
    echo "You must enter a project name."
    exit 1
else
    echo "Project name is: $project_name"
fi


# Create a new directory for the project
mkdir $project_name
cd $project_name

# Initialize a new npm project
npm init -y

# Install dependencies
yarn add express cors helmet multer express-async-errors express-rate-limit
yarn add --dev typescript @types/express @types/cors @types/multer ts-node nodemon eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-prettier eslint-plugin-prettier

# Create tsconfig.json
cat > tsconfig.json <<EOL
{
  "compilerOptions": {
    "target": "es6",
    "module": "commonjs",
    "rootDir": "src",
    "outDir": "dist",
    "sourceMap": true,
    "resolveJsonModule": true,
    "lib": ["es6", "dom"],
    "esModuleInterop": true,
    "noPropertyAccessFromIndexSignature": true
  },
  "include": [
    "src/**/*.ts"
  ],
  "exclude": [
    "node_modules"
  ]
}
EOL

# set up env
yarn add dotenv

# Create .env file
cat > .env <<EOL
PORT=5000
EOL

# Logger
yarn add winston morgan

# Create .eslintrc.json
cat > .eslintrc.json <<EOL
{
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint", "prettier"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier",
    "plugin:prettier/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": "warn"
  }
}
EOL

# Create .prettierrc.json
cat > .prettierrc.json <<EOL
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2
}
EOL

# Update package.json with the necessary scripts
npx json -I -f package.json -e "this.scripts={...this.scripts, 'build':'tsc', 'start':'tsc && node dist/index.js','dev':'nodemon --watch \"src/**/*.ts\" --exec \"ts-node\" src/index.ts','lint:check':'eslint .','lint:fix':'eslint . --fix','format:check':'prettier --ignore-path .gitignore --check \"**/*.[jt]s?(on)\"', 'format:fix':'prettier --ignore-path .gitignore --write \"**/*.[jt]s?(on)\"'}"
# npx json -I -f package.json -e "this.scripts={...this.scripts, 'build':'tsc', 'start':'tsc && node dist/index.js','dev':'nodemon --watch \"src/**/*.ts\" --exec \"ts-node\" src/index.ts','lint':'eslint .','lint:fix':'eslint . --fix'}"


# Create src directory and index.ts file
mkdir src

cat > src/logger.ts <<EOL
import path from 'path';
import winston from 'winston';

export const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({
      filename: path.join(__dirname, 'logs', 'error.log'),
      level: 'error',
    }),
    new winston.transports.File({
      filename: path.join(__dirname, 'logs', 'combined.log'),
    }),
  ],
});

if (process.env['NODE_ENV'] !== 'production') {
  logger.add(
    new winston.transports.Console({
      format: winston.format.simple(),
    }),
  );
}
EOL

cat > src/index.ts <<EOL
import 'dotenv/config';
import express, { Application, Request, Response, NextFunction } from 'express';
import 'express-async-errors';
import rateLimit from 'express-rate-limit';
import cors from 'cors';
import helmet from 'helmet';
import { logger } from './logger';
import morgan from 'morgan';
// import multer from 'multer';

const app: Application = express();
const port = process.env['PORT'] || 5000;

// CORS configuration
app.use(cors());

// Helmet configuration
app.use(helmet());

// JSON data handling
app.use(express.json());

// Rate limit configuration
const limiter = rateLimit({
  windowMs: 1 * 1000, // 1 seconds
  max: 50,
  message: "You can't make any more requests at the moment. Try again later",
});
app.use(limiter);

// Morgan logging
app.use(morgan('dev'));

// Multer configuration
// const upload = multer();
// app.use(upload.array('files'));

app.get('/', async (req: Request, res: Response) => {
  res.status(200).send({ data: 'Hello from the TypeScript Server' });
});

// Catch-all route should be placed after all other routes and middleware
app.use('*', (req: Request, res: Response) => {
  res.status(404).send({ error: 'Route not found' });
});

// Error handling middleware
app.use(function (err, req, res, next) {
  logger.error(err.stack);
  res.status(500).send('Something went wrong1!');
});

app.listen(port, () => console.log(\`Server is listening on port \${port}!\`));
EOL

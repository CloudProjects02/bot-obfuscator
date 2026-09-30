FROM node:18-slim

# Install Lua
RUN apt-get update && apt-get install -y lua5.1 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies (no devDependencies)
RUN npm install --omit=dev

# Copy the rest of your application
COPY . .

EXPOSE 8080
CMD ["node", "server.js"]

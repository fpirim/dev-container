# Dev Container

This project sets up a public development environment using Docker. It includes various tools such as Java, Maven, Node.js, and code-server, along with optional Traefik integration for proxying services. The environment is ready for general-purpose development.

## Features
- **Java 11** via OpenJDK
- **Maven 3.8.8** for dependency management
- **Node.js 18.19.0** for JavaScript/TypeScript development
- **code-server** for running VS Code in a browser
- **Docker** for containerized development
- **Docker Compose** for containerized development management
- **Traefik** (optional) for reverse proxying code-server and applications

## Prerequisites
- Docker
- Docker Compose

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <repository-folder>
```

### 2. Create .env File
Create a `.env` file in the project root and set the `DOMAIN` environment variable:

```bash
DOMAIN=example.com
CERTRESOLVER=myresolver
SSH_AUTHORIZED_KEYS="ssh-rsa AAAAB3...key1 user1@host1
ssh-rsa AAAAB3...key2 user2@host2
ssh-rsa AAAAB3...key3 user3@host3
"
```

### 3. Build the Docker Image
To build the development container, run:

```bash
docker compose build
```

### 4. Run the Development Environment
Start the development environment using:

```bash
docker compose up -d
```

This will start the code-server, and the development environment will be available at `http://localhost:9394` (or configured with Traefik if `DOMAIN` is set).

### 5. Access the Workspace
You can access the code-server in a browser. By default, authentication is disabled (`--auth none`). The workspace directory is mounted in `/home/ubuntu/workspace`, and you can store project files there.

### Optional: Traefik Configuration
If you're using Traefik for proxying, uncomment the relevant sections in the `docker-compose.yml` file, and Traefik will expose the services on your defined `DOMAIN`. The sample .env file should include a `CERTRESOLVER` to handle TLS certificate resolution via Let's Encrypt or other providers.

Example .env file:
```bash
DOMAIN=example.com
CERTRESOLVER=myresolver
SSH_AUTHORIZED_KEYS="ssh-rsa AAAAB3...key1 user1@host1
ssh-rsa AAAAB3...key2 user2@host2
ssh-rsa AAAAB3...key3 user3@host3
"
```

### Volumes
The following data is persisted between container runs using Docker volumes:

`home` for /home/ubuntu

### Stopping the Environment
To stop the development container:

```bash
docker compose down
```
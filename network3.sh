#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

#Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to check and install Docker and Docker Compose
install_docker() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker not detected, installing..."
        sudo apt-get update
        sudo apt-get install ca-certificates curl gnupg lsb-release -y

        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Set up the Docker repository
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Authorize Docker files
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        # Install the latest version of Docker
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
        echo "Docker installation completed."
    else
        echo "Docker is already installed."
    fi

    # Check if Docker Compose is installed
    if docker compose version &> /dev/null; then
        echo "Docker Compose is already installed."
    else
        echo "Docker Compose is not installed. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
        echo "Docker Compose installation completed."
    fi
}

# Function to create the docker-compose.yml file
create_docker_compose() {
    user_email="vitacimin00@gmail.com"
    user_path="/root/network3/wireguard"  # Default path

    echo "Creating docker-compose.yml file..."
    mkdir -p network3
    cd network3
    touch docker-compose.yml
    cat > docker-compose.yml <<EOL
version: '3.3'
services:  
  network3-01:    
    image: aron666/network3-ai    
    container_name: network3-01    
    ports:      
      - 8080:8080/tcp
    environment:
      - EMAIL=$user_email
    volumes:
      - $user_path:/usr/local/etc/wireguard    
    healthcheck:      
      test: curl -fs http://localhost:8080/ || exit 1      
      interval: 30s      
      timeout: 5s      
      retries: 5      
      start_period: 30s    
    privileged: true    
    devices:      
      - /dev/net/tun    
    cap_add:      
      - NET_ADMIN    
    restart: always

  autoheal:    
    restart: always    
    image: willfarrell/autoheal    
    container_name: autoheal    
    environment:      
      - AUTOHEAL_CONTAINER_LABEL=all    
    volumes:      
      - /var/run/docker.sock:/var/run/docker.sock
EOL
    echo "docker-compose.yml created with your inputs."
    cd ..
}

# Function to start the Network3 node
start_node() {
    echo "Starting Network3 node..."
    cd network3
    docker compose up -d
    echo "Network3 node started."
    cd ..
}

# Function to check and return the IP for the binding URL
check_url() {
    # Get the machine's IP address
    ip_address=$(hostname -I | awk '{print $1}')
    
    if [ -z "$ip_address" ]; then
        echo "Could not retrieve IP address. Trying with external service..."
        ip_address=$(curl -s ifconfig.me)
    fi

    if [ -z "$ip_address" ]; then
        echo "Could not retrieve IP address. Please check your network settings."
        return 1
    fi

    # Construct the URL
    node_url="http://account.network3.ai:8080/main?o=$ip_address:8080"
    echo "Bind your node using the following URL: $node_url"
    echo "You can open the URL above at Google/Brave/Mozilla."
}

# Main logic
main() {
    install_docker
    create_docker_compose
    start_node
    check_url
    echo "Process completed automatically!"
}

# Run the main function
main

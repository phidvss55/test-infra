#!/bin/bash

# constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 decode <base64-string>           - Decode a base64 string"
    echo "  $0 start-argocd                     - Start ArgoCD"
    echo "  $0 forward-argocd [local-port]      - Forward ArgoCD server port (default: 8080)"
    echo "  $0 help                             - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 decode SGVsbG8gV29ybGQ="
    echo "  $0 start-argocd"
    echo "  $0 forward-argocd"
    echo "  $0 forward-argocd 9090"
}

# Function to decode base64
decode_base64() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No base64 string provided${NC}"
        echo "Usage: $0 decode <base64-string>"
        exit 1
    fi
    
    echo -e "${GREEN}Decoding base64 string...${NC}"
    echo "$1" | base64 -d
    echo ""
}

# Function to start ArgoCD
start_argocd() {
    echo -e "${GREEN}Starting ArgoCD...${NC}"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check if ArgoCD namespace exists
    if ! kubectl get namespace argocd &> /dev/null; then
        echo -e "${YELLOW}ArgoCD namespace not found. Installing ArgoCD...${NC}"
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        echo -e "${GREEN}ArgoCD installed successfully${NC}"
    else
        echo -e "${GREEN}ArgoCD namespace already exists${NC}"
    fi
    
    # Wait for ArgoCD to be ready
    echo -e "${YELLOW}Waiting for ArgoCD pods to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    
    echo -e "${GREEN}ArgoCD is ready!${NC}"
    echo -e "${YELLOW}Get initial admin password with:${NC}"
    echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

# Function to forward ArgoCD port
forward_argocd() {
    local LOCAL_PORT=${1:-8080}
    
    echo -e "${GREEN}Forwarding ArgoCD server port...${NC}"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check if ArgoCD service exists
    if ! kubectl get svc argocd-server -n argocd &> /dev/null; then
        echo -e "${RED}Error: ArgoCD server service not found${NC}"
        echo -e "${YELLOW}Try running: $0 start-argocd${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Port forwarding argocd-server on localhost:${LOCAL_PORT}${NC}"
    echo -e "${YELLOW}Access ArgoCD at: https://localhost:${LOCAL_PORT}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
    echo ""
    
    kubectl port-forward svc/argocd-server -n argocd ${LOCAL_PORT}:443
}

# Main script logic
case "$1" in
    decode)
        decode_base64 "$2"
        ;;
    start-argocd)
        start_argocd
        ;;
    forward-argocd)
        forward_argocd "$2"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Error: Invalid command${NC}"
        echo ""
        usage
        exit 1
        ;;
esac
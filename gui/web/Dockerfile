# Use a slim base image
FROM nginx:alpine

# Copy your index.html file into the Nginx document root
COPY index.html /usr/share/nginx/html/

# Expose port 80 (HTTP)
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

# CBRE Cloud Infrastructure Recommendation Engine

A client-side web application that helps CBRE clients choose an AWS infrastructure architecture based on their requirements.

## Features

- Interactive question-based recommendation system
- Modular architecture with separate JavaScript modules
- Generates Terraform code for the recommended infrastructure
- Interactive architecture topology diagram visualization
- Dark mode support with theme switcher
- Integrated AI chat assistant with real Claude API connection
- Remembers user's theme preference
- Pure client-side implementation (HTML, CSS, and JavaScript)
- Can be run directly in a web browser without a server

## File Structure

```
/cloud-infrastructure-agent/
│
├── index.html                 # Main HTML file
├── README.md                  # This file
│
├── js/                        # JavaScript modules
│   ├── recommendation-agent.js # Logic for recommendations
│   ├── ui-controller.js       # UI interaction handling
│   ├── terraform-generator.js # Terraform code generation
│   ├── topology-mapper.js     # Architecture diagram visualization
│   ├── theme-switcher.js      # Dark/light mode functionality
│   └── chat-interface.js      # Claude chat assistant interface
│
└── css/                       # Optional: CSS files if separated from HTML
    └── styles.css             # Optional: Separated CSS
```

## How to Run

Since this is a client-side only application, you can run it in several ways:

### Option 1: Open directly in a browser

Simply open the `index.html` file in a modern web browser.

**Note:** Some browsers may block module imports when opening files directly. If you encounter issues, use one of the other methods below.

### Option 2: Use a simple HTTP server

1. Using Python:
   ```
   # Python 3
   python -m http.server
   
   # Python 2
   python -m SimpleHTTPServer
   ```

2. Using Node.js (install `http-server` first):
   ```
   npx http-server
   ```

3. Then navigate to `http://localhost:8000` in your browser.

### Option 3: Use VS Code Live Server extension

If you use Visual Studio Code, you can install the "Live Server" extension and right-click on `index.html` to open it with Live Server.

## Claude API Integration

The application includes a chat interface that connects to the Anthropic Claude API through a proxy server. To use this feature:

1. Install Node.js if you don't have it already (https://nodejs.org/)
2. Open a terminal in the project directory
3. Run `npm install` to install dependencies
4. Either:
   - Edit the `server.js` file and replace the placeholder API key, or
   - Set the CLAUDE_API_KEY environment variable: `export CLAUDE_API_KEY=your-api-key-here` (Linux/Mac) or `set CLAUDE_API_KEY=your-api-key-here` (Windows)
5. Run `npm start` to start the proxy server
6. Access the application at http://localhost:3000

The proxy server runs on port 3000 by default and serves both the static files for the application and forwards API requests to Claude.

**Connection Testing:**
- You can test the connection at any time by typing `/test_connection` in the chat
- The connection status is displayed in the chat button and header

### Why a Proxy Server?

Browser security restrictions (CORS) prevent direct API calls to Claude from client-side code. The proxy server:
1. Receives requests from your browser
2. Forwards them to Claude's API
3. Returns the responses to your application

### Fallback Mode

If you don't have a Claude API key or encounter connection issues, the chat will fall back to a simple rule-based response system that can answer basic questions about AWS services.

## Customization

To add new infrastructure patterns or modify existing ones:

1. Edit `recommendation-agent.js` to add new patterns to the `patterns` object
2. Add the corresponding Terraform generator method in `terraform-generator.js`
3. Add the new generator to the `templates` object in the `TerraformGenerator` constructor

## Browser Compatibility

This application uses ES6 modules and should work in all modern browsers including:
- Chrome (version 61+)
- Firefox (version 60+)
- Safari (version 11+)
- Edge (version 16+)

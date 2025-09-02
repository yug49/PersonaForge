import React from "react";
import { ExclamationTriangleIcon } from "@heroicons/react/24/outline";

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error("Error caught by boundary:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="max-w-md mx-auto text-center p-6">
            <ExclamationTriangleIcon className="mx-auto h-16 w-16 text-red-400 mb-4" />
            <h2 className="text-xl font-bold text-gray-900 mb-4">
              Application Error
            </h2>
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
              <p className="text-sm text-red-800 mb-2">
                <strong>Browser Extension Issue Detected</strong>
              </p>
              <p className="text-xs text-red-700">
                This error is often caused by wallet extensions blocking
                localhost. Please try the following:
              </p>
              <ul className="text-xs text-red-700 mt-2 text-left list-disc list-inside">
                <li>Refresh the page (Ctrl+F5 or Cmd+Shift+R)</li>
                <li>Check your wallet extension settings</li>
                <li>Enable developer mode in extension settings</li>
                <li>Try opening in incognito mode</li>
              </ul>
            </div>
            <button
              onClick={() => window.location.reload()}
              className="btn-primary"
            >
              Reload Application
            </button>
            <p className="text-xs text-gray-500 mt-4">
              Error: {this.state.error?.message}
            </p>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;

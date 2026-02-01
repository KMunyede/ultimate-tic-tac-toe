module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    // Add these lines to fix the Windows conflicts:
    "linebreak-style": "off", // Allows Windows CRLF without errors
    "object-curly-spacing": ["error", "always"], // Enforces { key: value } style
    "indent": ["error", 2],

    "max-len": ["error", { "code": 120 }], // Increases limit from 80 to 120
    "require-jsdoc": "off", // Standardizes indentation
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};

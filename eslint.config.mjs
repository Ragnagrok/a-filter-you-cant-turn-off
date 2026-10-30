// The "locked" TypeScript: rules that forbid the ways around the type checker.
import tseslint from "typescript-eslint";

export default tseslint.config({
  files: ["cases/**/*.ts"],
  extends: [tseslint.configs.base],
  languageOptions: { parserOptions: { projectService: true } },
  rules: {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-non-null-assertion": "error",
    "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-return": "error",
    "@typescript-eslint/no-unsafe-member-access": "error",
    "@typescript-eslint/switch-exhaustiveness-check": "error",
  },
});

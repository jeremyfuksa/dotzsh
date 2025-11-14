## Spinner Handling Update
- `update-all.sh` now detects non-TTY outputs or `DOTZSH_NO_SPINNER=1` and disables the spinner animation, falling back to simple progress messages.
- When a real TTY is present, the spinner uses `\r\033[K` to rewrite the same line each tick, preventing multi-line flooding in logs.
- Future logging or UI changes should respect this behavior to keep automated logs tidy.
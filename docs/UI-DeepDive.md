The Architecture of Readability: An Engineering Guide to CLI Badges and Log AlignmentPrinciples of Modern CLI Badge and Log DesignThe challenge of "hard to read" and "ragged" output in command-line interface (CLI) scripts is not a cosmetic issue; it represents a fundamental failure in user experience (UX). Modern CLI applications, particularly for development and operations, must adhere to core usability heuristics, chief among them being the "visibility of system status".1 When a user executes an install or update script, they are often left staring at a blinking cursor, unable to distinguish between a working process and a frozen one.2 This ambiguity erodes trust and complicates debugging.The primary solution is to provide a "reaction for every action".1 The UI badges and log messages in a script are this reaction. They transform a black box into a transparent, observable process. An aligned, readable log is the visual proof that the system is working, providing clear indications of progress, success, or failure.The Anatomy of a Modern Badge: A Composite SystemThe most effective, modern "badges" are not just text labels. They are a composite system of three elements, each serving a distinct purpose. This system is designed to serve two audiences simultaneously: the human operator, who needs fast, glanceable status, and the human developer or machine, who needs clear, parsable data for filtering and debugging.Color: Color is the most powerful pre-cognitive tool for attracting the user's eye.3 A semantic color system allows the operator to assess the state of the process without reading a single word.Green: Used for success, completion, and positive outcomes.4Red: Universally reserved for errors, failures, and fatal actions.4Yellow: Indicates warnings, non-blocking issues, or states that require user attention.4Blue / Cyan: Typically used for informational messages, debug output, or to denote the start of a new step.3Symbol (Iconography): While color draws the eye, a symbol provides faster recognition than a text label. Unicode provides a rich, standardized set of icons that function effectively in most modern terminals.Success: ✔ (Checkmark)Error / Fatal: ✖ (Cross)Info / Step: ℹ (Info) or ➤ (Arrow)Warning: ⚠ (Warning sign)Pending / Await: ⏳ (Hourglass) or … (Ellipsis) 5Label: The text label provides explicit clarification and, most importantly, a stable string for filtering. While an operator glances at ✔ (green), a developer debugging a failed CI build will grep the log file for .[6] Effective labels are typically uppercase, concise, and bracketed (e.g., `[INFO]`, , , ).A modern, best-practice badge combines all three elements, such as a green or a red. This composite approach serves both the immediate need for status visibility and the long-term need for maintainability and analysis.The Message Content: Context is KingA well-designed badge is rendered useless if the subsequent message is cryptic. The log message must provide actionable context.7 A simple message like "Transaction failed" is a diagnostic dead end. A strong log message provides the "what" and "why," such as "Transaction 324 is failed: the checksum is incorrect".7 For install scripts, this means logging which package is being installed, what file is being configured, or which ID has failed.The "Quiet" Principle and Machine-ReadabilityFinally, this "pretty" output, while invaluable for an interactive human user, is noise for an automated system. A script running in a CI/CD pipeline or as part of a larger automated flow should not produce colorful, human-centric logs. Therefore, a best practice is to offer a --quiet or --silent flag to suppress all non-essential diagnostic output, allowing the script to fail silently (with a non-zero exit code) or produce only machine-readable results.2 This leads directly to the most critical architectural decision in CLI design: where to print these messages.A Critical Foundation: Standard Streams (stdout vs. stderr)Before any alignment code can be written, a foundational architectural decision must be made: where log messages belong. A failure to distinguish between standard output (stdout) and standard error (stderr) is the most common and severe error in CLI tool design, rendering an otherwise functional tool "broken" from the perspective of automation and composability.Defining the StreamsEvery standard Unix-like process is given three pre-connected communication channels, known as standard streams 8:stdout (Standard Output / File Descriptor 1): This stream is for the result of the program. It is the primary, machine-readable output that the program was designed to produce.10 For grep, this is the matching lines. For cat, it is the file contents. For an install script, it might be the final installation path or a JSON manifest of installed packages.stderr (Standard Error / File Descriptor 2): This stream is for the dialogue with the user. It is the channel for all human-facing diagnostics: log messages, errors, warnings, prompts, status updates, and progress bars.10Why This Separation is Non-NegotiableThe "UNIX philosophy" is built on the idea of simple tools that can be chained together using pipes (|) to perform complex tasks.8 This separation of streams is the enabler of that philosophy.When a user pipes one command into another (command1 | command2), only the stdout of command1 is connected to the stdin of command2. The stderr of command1 is not piped; it is passed directly to the user's terminal.8This mechanism is what allows a tool like curl to function correctly. The command curl -v http://google.com | grep 301 works perfectly 14:curl downloads the page HTML (the result) and prints it to stdout.curl also prints its verbose connection logs (the dialogue) to stderr.The | pipe only sends the stdout (HTML) to grep.The user's terminal simultaneously displays the stderr (logs), while grep filters the clean HTML.Now consider a script that incorrectly prints its logs and its result to stdout. If an install script prints [INFO] Starting install... to stdout and then prints a JSON result {"version": "1.2.0"} to stdout, it is fundamentally broken. The command your-script.sh | jq. will fail because jq will receive the [INFO] log message, which is not valid JSON, thus contaminating the data stream and breaking the chain.The Cardinal Rule for Your ScriptsThis leads to an inviolable rule for all robust CLI development:All badges, log messages, warnings, errors, and progress indicators MUST be written to stderr (File Descriptor 2).The actual, primary result of the script (e.g., a final version number, a file path, a JSON object) should be the only data printed to stdout (File Descriptor 1).Implementation:Bash/sh: Use redirection. echo "[INFO] Starting..." >&2Python: The logging module correctly defaults to stderr.15 For manual printing, use print("[INFO] Starting...", file=sys.stderr). Progress bars like tqdm also correctly default to stderr.16Node.js: Use console.error("[INFO] Starting..."). Unlike console.log (which prints to stdout), console.error correctly prints to stderr and should be used for all diagnostic logging.The Core Technical Challenge: Achieving Alignment with ANSI ColorWith the architectural foundation of stderr established, we can now address the root cause of the "ragged" and "no alignment" output. The problem is that standard padding and formatting functions are "tricked" by the "invisible" characters used to produce color.The Problem: "Invisible" Characters Break String MathWhen a terminal prints colored text, it does so by processing ANSI escape codes. These codes are sequences of non-printing characters that instruct the terminal to change its state (e.g., "switch to green") and then switch back ("reset to normal").Consider the plain text string for a badge:String: "  [OK]  "Visible Length: 8 charactersByte Length: 8 charactersNow consider the same badge, but colored green:String (representation): "\033[32m  [OK]  \033 Standard formatting functions, like Bash's printf, Python's .ljust(), or JavaScript's .padEnd()`, operate on the byte length of the string, not its visible length.The Failure Scenario 17:A script has a green badge [OK] and a red badge [FAIL].The goal is to pad all badges to a fixed width of 15 characters to align the messages.The code attempts: printf "%-15s" "\033[32m  [OK]  \033   string, followed immediately by the log message.This process repeats for [FAIL], which may have a different-length color code, resulting in the "ragged" output.The Two-Part Solution: The "Color-Safe Padding" AlgorithmTo correctly pad a colored string, the calculation must be based on its visible length, not its byte length. This requires a universal, two-step algorithm that works in any language.Step 1: Get the Visible LengthThe only reliable way to get the visible length is to temporarily strip all ANSI color codes from the string and measure the result.19Regex: The most common regular expression to match and remove ANSI escape codes is \x1b\[[0-9;]*m (or variations).20Libraries: Dedicated libraries exist for this, such as strip-ansi in Node.js 23 or ansilen() from Python's ansiwrap module.19Step 2: Calculate and Apply PaddingOnce the true visible length is known, the correct padding can be calculated and appended to the original, colored string.The universal "color-safe padding" algorithm is as follows:function pad_right_ansi(colored_string, target_width):
    // 1. Strip codes to get visible length
    stripped_string = strip_ansi(colored_string)  [20, 23]
    visible_length = length(stripped_string)     

    // 2. Calculate padding needed
    IF visible_length >= target_width:
        RETURN colored_string  // No padding required

    padding_needed = target_width - visible_length 
    padding_spaces = " " * padding_needed

    // 3. Append padding to the ORIGINAL colored string
    RETURN colored_string + padding_spaces
This algorithm is the definitive solution to the alignment problem. The following implementation guides provide language-specific applications of this exact logic.Implementation Guide: Robust Logging in Shell Scripts (Bash/sh)For existing shell scripts, this logic can be implemented directly using standard Unix tools, providing an immediate fix.The Native Tools: tput and printftput: This is the standard, portable utility for terminal control.24 Instead of hard-coding raw ANSI escape codes (e.g., `\033printf: This is the built-in shell command for formatted output. The basic (and, as established, flawed) pattern for alignment is printf '%-15s: %s\n' "$BADGE" "$MESSAGE".26The "False Friend": The column CommandDevelopers often discover the column utility and believe it to be a magic solution for tabular data.29 Piping output through | column -t can automatically align text into columns.However, column is a "false friend" for this specific use case. It suffers from the exact same problem as printf: it cannot correctly calculate the width of strings containing ANSI color codes and will produce misaligned output.34 The printf approach, while more manual, is superior because it allows for the explicit implementation of the color-safe padding algorithm.The Solution: A Production-Grade Bash Logging FunctionThe following is a complete, production-grade logging framework for Bash scripts. It synthesizes best practices by using tput for colors 26, detecting if stderr is a terminal 36, implementing the color-safe padding algorithm, and providing simple, reusable logging functions.37This code can be copied directly into the top of an existing install or update script to fix all alignment issues.Bash#!/bin/bash

# --- A. Setup: Colors and Constants ---

# Define the fixed width for the badge column (e.g., 14 characters)
# All badges will be padded to this visible width, creating alignment.
BADGE_WIDTH=14

# Use tput for portable colors and styles 
# Check if stderr (FD 2) is a terminal 
if [ -t 2 ]; then
  NCOLORS=$(tput colors)
  if [ $? -eq 0 ] &&; then
    # Enable colors and styles
    BOLD=$(tput bold)
    NORMAL=$(tput sgr0)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 6)
  else
    # Disable colors if terminal does not support them
    BOLD=""
    NORMAL=""
    GREEN=""
    YELLOW=""
    RED=""
    BLUE=""
  fi
fi

# --- B. The Color-Safe Padding Algorithm (Section III) ---

# A function to strip ANSI codes from a string using sed 
# This is necessary to get the *visible* length for padding.
strip_ansi() {
  # The -e flag allows for the \x1b (ESC) character
  echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# The main logging function.
# Arguments:
#   $1: The badge string (with color codes)
#   $2: The message string
log() {
  local badge_string="$1"
  local message="$2"
  
  # 1. Get the visible length of the badge by stripping ANSI codes
  #    and counting characters with wc -m.
  local visible_badge_length=$(strip_ansi "$badge_string" | wc -m)
  
  # 2. Calculate the padding needed
  local padding_needed=0
  if; then
    padding_needed=$((BADGE_WIDTH - visible_badge_length))
  fi
  
  # Create the padding string
  local padding=$(printf '%*s' $padding_needed '')
  
  # 3. Print the final, aligned, two-column message
  #    - %s: The original, colored badge
  #    - %s: The calculated padding
  #    - %s\n: The log message and a newline
  #
  # This output is redirected to stderr (>&2) 
  printf "%s%s  %s\n" "$badge_string" "$padding" "$message" >&2
}

# --- C. Reusable Logging Functions [36, 37] ---
# These functions provide a simple API for the rest of the script.

log_info() {
  log "${BLUE}${BOLD}[ℹ INFO]${NORMAL}" "$1"
}

log_step() {
  log "${BLUE}${BOLD}${NORMAL}" "$1"
}

log_warn() {
  log "${YELLOW}${BOLD}${NORMAL}" "$1"
}

log_success() {
  log "${GREEN}${BOLD}${NORMAL}" "$1"
}

log_error() {
  log "${RED}${BOLD}[✖ FAIL]${NORMAL}" "$1"
}

# --- D. Example Usage ---

log_step "Cloning repository 'my-project'..."
# git clone...
sleep 0.5
log_success "Repository cloned."

log_step "Installing dependencies (this may take a moment)..."
# npm install...
sleep 1
log_warn "npm-audit found 3 moderate vulnerabilities."
log_success "Dependencies installed."

log_step "Configuring database connection..."
# some_command_that_fails...
sleep 0.5
log_error "Failed to connect to database at 'localhost:5432'."
log_info "To fix this, check that the database server is running."
This solution directly addresses the "ragged" output problem by ensuring every badge has a uniform visible width, which in turn forces all subsequent messages into a perfectly aligned second column.Implementation Guide: Advanced Logging in PythonFor scripts written in Python, the core problem remains the same, but the solutions can be more elegant and powerful, culminating in dedicated libraries that handle all layout declaratively.The "Simple but Flawed" Way: f-strings and .ljust()A developer's first instinct in Python is to use string formatting methods like .ljust() or f-string alignment.38Python# The FLAWED approach
GREEN = '\033{NORMAL}"

# This FAILS. len(badge) is ~17, not 8.
print(f"{badge.ljust(15)} Message is NOT aligned.")
This fails for the same reason it does in Bash: len(colored_badge) returns the byte length (e.g., 17), not the visible length (e.g., 8), so .ljust(15) does nothing.18The "Manual Color-Safe Solution": ansilen()The correct manual implementation involves porting the color-safe padding algorithm from Section III. This requires a function to get the visible length of the string, either by using a regex 20 or a library like ansiwrap, which exports an ansilen() function.19This ansi_ljust function is the correct manual implementation:Pythonimport re
import sys

def strip_ansi(text):
    """Remove ANSI color codes from a string """
    return re.sub(r'\x1b\[[0-9;]*m', '', text)

def ansi_ljust(s, width):
    """
    Color-safe ljust. Implements the algorithm from.
    """
    visible_length = len(strip_ansi(s))
    needed = width - visible_length
    if needed > 0:
        return s + ' ' * needed
    else:
        return s

# --- Example Usage ---
GREEN = '\033
badge_ok = f"{GREEN}{NORMAL}"
print(f"{ansi_ljust(badge_ok, BADGE_WIDTH)}  Message is aligned.", file=sys.stderr)

badge_fail = f"{RED}[✖ FAIL]{NORMAL}"
print(f"{ansi_ljust(badge_fail, BADGE_WIDTH)}  This message is also aligned.", file=sys.stderr)
This works, but it is cumbersome and requires manual management of state and color codes.The Superior Solution: The rich LibraryThe definitive, best-practice solution in Python is to use the rich library.41 rich is a powerful library for "rich text and beautiful formatting in the terminal".41Using rich represents a paradigm shift from an imperative approach to a declarative one. Instead of imperatively calculating padding (padding = width - len), a developer declares the desired layout, and rich handles all the complex implementation (ANSI, terminal width, text wrapping) automatically.For this specific use case, the rich.Table class is the ideal tool.41 The two-column layout described in the query is simply a borderless table. This not only solves the alignment problem but also correctly handles long messages by wrapping them within their column—a significant advantage over the printf solution, which would break the layout.The following code produces a perfect, robust, two-column layout that automatically respects terminal width and text wrapping.Pythonimport time
from rich.console import Console
from rich.table import Table

# Initialize a Console, directing output to stderr 
console = Console(stderr=True)

# Create a borderless table to act as our log formatter [41, 42]
# Table.grid() is a simple table with no lines
# expand=True allows the last column to fill the terminal width
log_table = Table.grid(expand=True)

# Add a fixed-width column for the badge
log_table.add_column(width=15, no_wrap=True)
# Add a second, flexible column for the message
log_table.add_column() 

# --- Example Usage ---
# Use rich's built-in console markup for colors and style
# https://rich.readthedocs.io/en/latest/markup.html

log_table.add_row(
    "[bold blue][/bold blue]",
    "Cloning repository 'my-project'..."
)
time.sleep(0.5)
log_table.add_row(
    "[bold green][/bold green]",
    "Repository cloned."
)

log_table.add_row(
    "[bold blue][/bold blue]",
    "Installing dependencies..."
)
time.sleep(1)
log_table.add_row(
    "[bold yellow][/bold yellow]",
    "npm-audit found 3 moderate vulnerabilities."
)
log_table.add_row(
    "[bold green][/bold green]",
    "Dependencies installed."
)

log_table.add_row(
    "[bold blue][/bold blue]",
    "Configuring database connection..."
)
time.sleep(0.5)
log_table.add_row(
    "[bold red][✖ FAIL][/bold red]",
    "Failed to connect to database at 'localhost:5432'. "
    "This is a very long error message that will be "
    "automatically and correctly wrapped to the next line, "
    "maintaining the column structure and readability."
)

# Print the entire table to the console
console.print(log_table)
This rich.Table approach is the gold standard for formatted, aligned logging in Python. For simpler column layouts without wrapping, rich.Columns is also an option.41Implementation Guide: Modern Logging in Node.jsFor JavaScript-based scripts, such as those run via npm in a package.json, the ecosystem provides excellent, purpose-built tools to solve this problem.The "Manual" Approach: chalk + strip-ansi + .padEnd()The manual algorithm from Section III can be implemented using three key packages:chalk: The industry-standard library for terminal string styling.4strip-ansi: The standard library for removing ANSI escape codes.22.padEnd(): A native JavaScript string method for padding.47This manual implementation looks as follows:JavaScriptimport chalk from 'chalk';
import stripAnsi from 'strip-ansi';

const BADGE_WIDTH = 15;

/**
 * Color-safe padEnd. Implements the algorithm from Section III.
 * @param {string} s - The string to pad (with colors).
 * @param {number} width - The target visible width.
 */
function ansi_pad_end(s, width) {
    const visible_length = stripAnsi(s).length; // 
    const needed = width - visible_length;
    if (needed > 0) {
        return s + ' '.repeat(needed);
    }
    return s;
}

// --- Example Usage ---

// Remember to use console.error to log to stderr 
const badge_ok = chalk.green.bold('');
console.error(
    `${ansi_pad_end(badge_ok, BADGE_WIDTH)}  Message is aligned.`
);

const badge_fail = chalk.red.bold('[✖ FAIL]');
console.error(
    `${ansi_pad_end(badge_fail, BADGE_WIDTH)}  This message is also aligned.`
);
The "Batteries-Included" Solution: signaleWhile the manual approach works, the Node.js ecosystem provides a superior solution. It is important to differentiate between two types of logging libraries:Structured Loggers: Libraries like pino, winston, and bunyan are high-performance loggers designed to output structured JSON for machine consumption.49 They are the wrong tool for building a human-readable CLI UI.CLI UI Loggers: Libraries like signale are specifically "designed for CLI applications" and "clean and beautiful output".5For this use case, signale is the correct, modern tool. It solves both problems at once:It provides 19+ "modern best practice" badges out-of-the-box (e.g., success, error, await, fatal).5It handles all alignment, padding, and formatting automatically.Comparing chalk and signale is illustrative: chalk gives you the tools to build a badge (the color); signale is the badge system, pre-built and ready to use.53Example Implementation with signale:JavaScriptimport signale from 'signale';
import { EOL } from 'os'; // End of Line

// Signale's loggers are pre-built with badges, colors, and alignment 

signale.start('Starting build process...');

signale.await('[1/3] Cloning repository "my-project"...');
//... git clone...
signale.success('[1/3] Repository cloned.');

signale.await('[2/3] Installing dependencies...');
//... npm install...
signale.warn('npm-audit found 3 moderate vulnerabilities.');
signale.success('[2/3] Dependencies installed.');

signale.await('[3/3] Configuring database connection...');
//... command fails...
const error = new Error("Failed to connect to database at 'localhost:5432'.");
signale.fatal(`${error.message}${EOL}  To fix this, check that the database server is running.`);
This code produces a beautiful, aligned, and stateful-looking log with minimal effort.5 For Node.js scripts, signale is the most direct and modern solution.High-Level Frameworks for Turnkey CLI ExperiencesThe solutions above perfect the log stream. However, for install and update scripts, a more advanced UI pattern exists that offers a superior user experience: the task list.The Task-Based UI vs. The Stream-Based LogThe printf or signale approach produces a "stateless" stream. Lines appear one after another and scroll away. A task runner, by contrast, presents a "stateful" UI. It renders a list of all tasks (pending, complete, or failed) and updates their status in-place. This provides a much higher level of "visibility of system status" 1 by showing the user the entire process at a glance—what's done, what's in progress, and what's left to do.This pattern is the true "modern best practice" for a multi-step install script.Recommended ToolsNode.js: listr / listr2This is the gold standard for this use case.54 A listr UI (as seen in its demo 54) first displays:[ ] Downloading prerequisite
[ ] Installing dependencies
[ ] Building project
As the script runs, it updates the UI in-place using spinners and status changes:[✔] Downloading prerequisite
[⏳] Installing dependencies
[ ] Building project
If a task fails, it stops and displays the error clearly:[✔] Downloading prerequisite
[✔] Installing dependencies
[✖] Building project
   > Error: Build command failed with exit code 1
This provides an exceptionally clean and professional user experience for a sequence of tasks.Python: rich.Progress / rich.TableThe rich library provides the components to build this stateful UI. A developer can use rich.Progress 41 to manage spinners and progress bars, and compose it with a rich.Table 41 to create a dynamic task list that updates in real-time, achieving a similar effect to listr.For any script involving more than 3-4 sequential steps, refactoring to a task-based UI pattern is the recommended strategic direction.Final Recommendations and Strategic ApproachThe problem of "ragged" log output is solvable. The solution begins with an architectural commitment to using stderr for all diagnostics and is implemented by correctly calculating padding around "invisible" ANSI color codes.Decision Matrix: Choosing Your ApproachThe optimal solution depends on the script's language and the developer's goals. The following table summarizes the primary implementation strategies.ApproachLanguageBest ForKey Feature(s)Key SourcesPadded printfBash/shImmediate Fix. Fixing existing shell scripts with no new dependencies.Universal, portable, manually implements color-safe padding.26rich LibraryPythonBest-in-Class UI. New Python scripts or major refactors.Declarative Table & Columns, automatic text wrapping, full TUI toolkit.41signale LibraryNode.jsTurnkey Badges. New Node.js scripts needing a beautiful log stream.19+ pre-built, aligned loggers (success, error, await) out-of-the-box.5listr / listr2Node.jsMulti-Step Processes. Install/update scripts with 3+ sequential steps.Stateful, "in-place" task list UI. Superior user experience.54Your Actionable Tiered StrategyA tiered strategy can be employed to move from the current "ragged" scripts to a modern, readable, and professional CLI experience.Tier 1 (Immediate Fix): Apply the Bash SolutionCopy the "Production-Grade Bash Logging Function" from Section IV into existing shell scripts. This is the fastest, most direct solution to the alignment problem. It correctly implements color-safe padding and enforces the critical stderr rule, fixing the "ragged" output immediately.Tier 2 (Mid-Term Refactor - "Best Practice"): Adopt a Dedicated LibraryIf the scripts are in Python or Node.js, the manual padding logic should be replaced with a dedicated library that handles this automatically.Python: Refactor the script to use the rich.Table (as a borderless grid) method from Section V.41 This provides a robust, auto-wrapping, two-column layout.Node.js: Refactor the script to use signale from Section VI.5 This provides a best-in-class badge UI with zero configuration.Tier 3 (Long-Term Vision - "Modern UX"): Adopt a Task-Runner UIFor complex, multi-step install and update scripts, the long-term goal should be to refactor the entire UI from a log stream to a task list. This represents the pinnacle of modern CLI design for this use case.Node.js: Re-architect the script around listr 54 to present a stateful, in-place-updating list of all install steps.Python: Use rich.Progress and rich.Table 41 to build a custom, stateful task dashboard.
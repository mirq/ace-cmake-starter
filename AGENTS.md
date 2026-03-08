# AGENTS.md — ace-cmake-starter

This file provides guidance for agentic coding assistants working in this repository.

---

## Project Overview

Cross-compiled Amiga (m68k) game built with CMake and the
[ACE (Amiga C Engine)](https://github.com/AmigaPorts/ACE) library. Primary
language is **C11**, with CMake for the build system. The target platform is
Motorola 68000 Amiga hardware/emulator.

Git submodules:
- `game/deps/ace` — ACE library (engine, headers, host tools)
- `AmigaCMakeCrossToolchains` — CMake toolchain files for m68k cross-compilation

---

## Build Commands

### Prerequisites

The Bartman GCC cross-compiler must be available. In CI it is provided via the
`mirqqq/amiga-development:v0.4` Docker image. Locally, it is bundled inside the
VSCode extension `bartmanabyss.amiga-debug`.

### Step 1 — Build ACE host tools (bitmap_conv, font_conv, palette_conv, etc.)

```sh
# Linux/macOS
./build_ace_tools.sh

# Windows
build_ace_tools.bat
```

Tools are output to `game/deps/ace/tools/bin/`.

### Step 2 — Configure the game

```sh
cd game
cmake -B ../game-build \
  -DCMAKE_TOOLCHAIN_FILE=../AmigaCMakeCrossToolchains/m68k-bartman.cmake \
  -DVSCODE_AMIGA_EXTENSION_PATH=/path/to/bartmanabyss.amiga-debug-1.7.9
```

### Step 3 — Build

```sh
cmake --build ../game-build --target showcase.elf -j 6
```

Outputs:
- `game-build/showcase.elf` — intermediate ELF binary
- `game-build/showcase.exe` — final Amiga hunk-format executable
- `game-build/dist/` — distributable directory (exe + assets)

### Useful CMake variables

| Variable | Description |
|---|---|
| `VSCODE_AMIGA_EXTENSION_PATH` | Path to Bartman VSCode extension (contains cross-compiler) |
| `M68K_CPU` | Target CPU: `68000` (default), `68010`, `68020`, `68040`, `68060` |
| `ACE_DEBUG` | Enables ACE debug/safety checks (`-DACE_DEBUG`) |
| `ACE_DEBUG_UAE` | Redirect log output to UAE emulator console |
| `ACE_LIBRARY_KIND` | `OBJECT` (default) or `STATIC` |

---

## Running Tests

There is **no unit test framework**. Tests are interactive visual demo scenes
that run on Amiga hardware or under the FS-UAE emulator.

Test scenes live in `game/src/test/` — each scene is a `.c`/`.h` pair
implementing three lifecycle functions:

```c
void gsTestNameCreate(void);   // initialize
void gsTestNameLoop(void);     // per-frame update
void gsTestNameDestroy(void);  // tear down
```

**Run all tests:** Build the project and launch `showcase.exe` in FS-UAE.
Use the VSCode launch config "Run-Debug-Linux" or "Run-Debug-Win32".

**Run a single test:** To start directly on a specific scene, open
`game/src/game.c` and change the initial state in `genericCreate()` from
`TEST_STATE_MENU` to the desired `TEST_STATE_*` enum value, then rebuild.

---

## CI

GitHub Actions (`.github/workflows/main-build.yml`) runs on push/PR to
`main`/`master` and on version tags. It uses the
`mirqqq/amiga-development:v0.4` Docker image and produces `game.lha` as a
build artifact. Releases are triggered by `v*.*.*` tags.

---

## Code Style

The authoritative style guide is:
`game/deps/ace/docs/contributing/codestyle.md`

### Language standard

- C11 (`CMAKE_C_STANDARD 11`)
- Compiler flags include `-Wall -Wextra`; treat all warnings seriously

### Indentation and braces

- **Tabs** for indentation (not spaces). Tab display width is left to the
  developer (2 or 4 spaces are both used by maintainers).
- One True Brace style, with `else` on its **own line** (not after `}`):
  ```c
  if(condition) {
    doA();
  }
  else {
    doB();
  }
  ```
- Always write braces, even for single-statement bodies.
- The only exception: `while(event()) continue;` may keep body on same line.

### Line length

Hard limit of **80 characters**. Fold function arguments when needed:

```c
void fnShort(t1 arg1, t2 arg2);

void fnWithManyArgs(
  t1 arg1, t2 arg2, t3 allArgsFitInOneLineButWithoutFnName
);

void fnWithTooManyArgs(
  t1 arg1, t2 arg2, t3 thereAreTooManyFnArgsToFitInOneLine,
  t4 arg4, t5 arg5, t6 soArgListIsBrokenToMultipleLines
);
```

### Naming conventions — Hungarian camelCase

**Type prefixes** (prepended to every identifier):

| Prefix | Type |
|---|---|
| `ub` | `UBYTE` / `uint8_t` |
| `uw` | `UWORD` / `uint16_t` |
| `ul` | `ULONG` / `uint32_t` |
| `ull` | `uint64_t` |
| `b`, `w`, `l`, `ll` | signed variants |
| `p` | pointer or array |
| `cb` | function pointer (callback) |
| `t` | typedef |
| `e` | enum instance |
| `s` | struct instance |
| `u` | union instance |
| `f` | float or fixed-point |
| `d` | double |

**Scope prefixes** (prepended before type prefix for non-local variables):

| Prefix | Scope |
|---|---|
| `g_` | global (visible from other files) |
| `s_` | file-static (visible only in current `.c` file) |

**Examples:**
```c
static tView *s_pTestCopperView;   // file-static pointer to typedef
static UBYTE s_ubBarCount = 0;     // file-static unsigned byte
tStateManager *g_pGameStateManager; // global pointer to typedef
UWORD uwBarY = 160;                 // local unsigned word
```

**Functions:** camelCase, no prefix, verb-noun style:
```c
void gsTestCopperCreate(void);
void blitRect(...);
void viewLoad(...);
```

**Macros:** `SCREAMING_SNAKE_CASE`:
```c
#define TEST_COPPER_COLOR_INSIDE 1
#define TWISTER_BLOCK_SIZE 32
```

**Enums:** typedef'd with `t` prefix; members in `SCREAMING_SNAKE_CASE`:
```c
typedef enum tTestState {
  TEST_STATE_MENU,
  TEST_STATE_BLIT,
  TEST_STATE_COUNT
} tTestState;
```

**Structs/unions:**
```c
typedef struct _tTypeName {
  // members
} tTypeName;
```

**File names:** `snake_case` (e.g., `buffer_scroll.c`, `blit.h`).

### Includes

Order strictly:
1. The header corresponding to the current `.c` file (own header first)
2. Standard library headers (`<stdlib.h>`, etc.)
3. ACE managers (`<ace/managers/...>`)
4. ACE utils (`<ace/utils/...>`)
5. Local project headers (`"game.h"`, `"menu/menu.h"`)

No blank lines between `#include` directives.

Use angle brackets for ACE/system headers; quotes for local project headers.

```c
#include "test/copper.h"
#include <ace/managers/copper.h>
#include <ace/managers/blit.h>
#include <ace/managers/key.h>
#include "game.h"
```

### Include guards

Use `#ifndef` guards (not `#pragma once`). Guard name reflects project name
and filesystem path, all uppercase:

```c
#ifndef _ACE_MANAGERS_BLIT_H_
#define _ACE_MANAGERS_BLIT_H_
// ...
#endif // _ACE_MANAGERS_BLIT_H_
```

For game project files use `_GAME_<PATH>_<FILE>_H_` pattern.

### Error handling

- No exceptions (C language, bare-metal target).
- Functions that can fail return `UBYTE` (0 = failure, 1 = success).
- Use `logWrite()`, `logBlockBegin()`, `logBlockEnd()` for diagnostics.
  These expand to no-ops in release builds.
- Debug vs. release duality via `ACE_DEBUG` macro:
  ```c
  #ifdef ACE_DEBUG
  #define blitRect(...) blitSafeRect(..., __LINE__, __FILE__)
  #else
  #define blitRect(...) blitUnsafeRect(...)
  #endif
  ```
- Use `0` (not `NULL`) as null pointer sentinel throughout the codebase.
- `message(FATAL_ERROR "...")` in CMake for missing tools or misconfigured build.

### Documentation

- All functions exported from a header **must** have Doxygen comments in the
  `.h` file. Use Javadoc style (`@param`, `@return`, `@file`, etc.).
- `static` functions in `.c` files should also be documented.
- Put `@file` doxygen comment immediately after the include guard.
- Keep functions short — if a function doesn't fit on one screen, split it.

# YARLib — Team Development Setup

**Shared GitHub repository:** https://github.com/Karpanda/yarlib  
**Course:** CMSC 451 — Senior Project  
**Goal:** Set up the same working development environment, use individual branches in Ben's shared repository, and test changes before pushing.

| Team member | Operating system | Development branch |
|---|---|---|
| Brenna | macOS | `brenna-dev` |
| Ben | macOS | `ben-dev` |
| Brandon | Windows | `brandon-dev` |

**We are not making personal forks.** Everyone already has access to Ben's repository. We clone that repository, work on our assigned branches, and use pull requests to merge reviewed work into `main`. Do not commit or push directly to `main`.

## 1. Clone the repository in VS Code

1. Sign in to GitHub and open **https://github.com/Karpanda/yarlib**.
2. On the repository page, click the green **Code** button.
3. Under **Local**, choose the **HTTPS** tab, then click the **copy** icon beside `https://github.com/Karpanda/yarlib.git`.
4. Open **VS Code** and choose **Terminal → New Terminal**. Navigate to the parent folder where you want the repository stored.
5. Clone and enter the repository:

   ```bash
   git clone https://github.com/Karpanda/yarlib.git
   cd yarlib
   ```

6. Open the cloned folder in VS Code using **File → Open Folder** (or **File → Open…** on macOS). The VS Code terminal should be inside `yarlib` for the following steps.

**Note:** If you have already cloned the repository, do not clone it again. Open your existing `yarlib` folder.

## 2. Configure your Git identity

Set your own full name and VCU email so commits show the correct author:

```bash
git config user.name "Your Full Name"
git config user.email "yourVCUemail@vcu.edu"
```

Verify:

```bash
git config user.name
git config user.email
```

These settings apply to this repository. The Git author name does not have to match your GitHub username. For GitHub to associate commits with your profile, verify that email under **GitHub Settings → Emails**.

## 3. Switch to your assigned branch

Fetch the branches:

```bash
git fetch origin
```

Run **only your own** command:

**Brenna:**
```bash
git switch --track origin/brenna-dev
```

**Ben:**
```bash
git switch --track origin/ben-dev
```

**Brandon:**
```bash
git switch --track origin/brandon-dev
```

If the branch already exists locally, use `git switch YOUR-BRANCH` instead.

Verify:

```bash
git branch --show-current
git status
```

The displayed branch should be yours, and the working tree should be clean. If you are on `main`, **stop and switch branches before editing**.

## 4. Install the development tools

Everyone needs:

- **Git** and **Visual Studio Code**
- **Alire** (Ada package manager): https://alire.ada.dev
- **GNAT** and **gprbuild**, installed/managed through Alire
- **Ada language support** in VS Code
- **SDL3** development libraries for your operating system

Check your tools from the repository root:

```bash
git --version
alr --version
alr exec -- gprbuild --version
```

Brenna's working versions were **Alire 2.1.1**, **GNAT Native 16.1.0**, and **gprbuild 26.0.1**. These are a reference, not confirmed required versions. If `gnat` or `gprbuild` is not available directly in your shell, try it through `alr exec`.

## 5. macOS setup — Brenna and Ben

### Install SDL3

Install Homebrew from https://brew.sh if needed, then run:

```bash
brew install sdl3
brew --prefix sdl3
```

### Set the platform and build

From the root `yarlib` directory:

```bash
export YARLIB_OS=macos
alr build
alr build --validation
```

`export YARLIB_OS=macos` applies to the current terminal session; repeat it in a new terminal if necessary. The validation build should finish successfully before you push changes.

### Build and run tests

```bash
cd tests
alr build
./bin/tests
```

Some unfinished milestone checks may display `TODO`; distinguish those from actual test failures.

### Build and run the showcase

From `tests`:

```bash
cd ../showcase
alr build
./bin/arena
```

The showcase should open a window. While the batcher is incomplete, it may report dropped quads; this is a milestone implementation issue rather than necessarily an installation failure.

### macOS troubleshooting note — duplicate `LC_RPATH`

Brenna's showcase **built successfully but initially failed when launched** with:

```text
dyld: duplicate LC_RPATH '/opt/homebrew/lib'
```

In `yarlib.gpr`, the macOS SDL3 linker line was:

```ada
Libs := Libs & ("-L/opt/homebrew/lib", "-L/usr/local/lib", "-lSDL3");
```

Removing the redundant library search paths fixed the launch issue on her Mac:

```ada
Libs := Libs & ("-lSDL3");
```

After that, `./bin/arena` launched and `alr build --validation` passed. The change was committed **only to `brenna-dev`**, in commit **`d5da309`** (`Fix duplicate macOS library search paths`). It is **not automatically present on `main`, `ben-dev`, or `brandon-dev`**.

**Ben:** You may not encounter this error even though you also use a Mac. First try the normal setup. If you see the same error, check whether this fix has already been incorporated; coordinate with the team rather than making an unrelated linker change.

## 6. Windows setup — Brandon

Use **VS Code's PowerShell terminal** for these commands.

### Install and verify

Install Git for Windows (https://git-scm.com), VS Code (https://code.visualstudio.com), Alire (https://alire.ada.dev), Ada language support, and SDL3 development/runtime libraries compatible with the selected Windows GNAT toolchain.

```powershell
git --version
alr --version
alr exec -- gprbuild --version
```

### Set the platform and build

From the root `yarlib` directory:

```powershell
$env:YARLIB_OS = "windows"
alr build
alr build --validation
```

The environment variable is set for the current PowerShell session.

### Build and run tests

```powershell
cd tests
alr build
.\bin\tests.exe
```

### Build and run the showcase

```powershell
cd ..\showcase
alr build
.\bin\arena.exe
```

**Windows-specific note:** These commands describe the intended workflow but have **not yet been verified on Brandon's machine**. SDL3 installation and runtime DLL placement may need adjustment. If Windows reports that `SDL3.dll` is missing, check that the matching SDL3 runtime is installed and accessible to the executable. Save the exact terminal error before changing project configuration. Do not apply macOS linker flags to Windows.

## 7. Confirm everything is ready

Each person should be able to check off:

- [ ] Cloned `Karpanda/yarlib` directly (no fork needed)
- [ ] Opened the correct `yarlib` folder in VS Code
- [ ] Configured Git full name and VCU email
- [ ] Confirmed the correct `*-dev` branch with `git branch --show-current`
- [ ] Installed Alire, GNAT, gprbuild, and SDL3
- [ ] Built the root project with `alr build`
- [ ] Passed `alr build --validation`
- [ ] Built and ran `tests`
- [ ] Built and launched `showcase/arena`

If a step fails, share the command, full error, operating system, and current branch with the team.

## 8. Project rules and reading

Before developing, read `README.md`, `ARCHITECTURE.md`, and `fall_plan.md`. The fall plan specifically recommends reviewing `src/yarlib-batch.ads`, `src/yarlib-core.ads`, and `showcase/src/arena_game.adb` before Milestone 1. Fall milestone work belongs in the library, ports, tests, and showcase—not `engine/`; the fall plan says **not** to build `engine/` yet because of an external dependency.

## 9. Quick reference — every time you make a commit

**Always work on your own branch, not `main`.** Run these from the repository root unless otherwise noted.

**1. Check branch and working tree before starting:**

```bash
git branch --show-current
git status
```

**2. Pull the latest version of your branch before making new edits:**

```bash
git pull --ff-only
```

If Git reports diverged history or a conflict, ask the team before proceeding.

**3. Make your changes. Then review exactly what changed:**

```bash
git diff
git status
```

**4. Build and test:**

```bash
alr build --validation
```

Also run the relevant tests and showcase for your changes, using the OS-specific commands above. Do not claim a test passed unless you actually ran it.

**5. Stage only the files you intend to commit:**

```bash
git add path/to/changed-file
```

For example, `git add yarlib.gpr` stages only that file. Then verify:

```bash
git diff --staged
git status
```

**6. Commit with your name/email already configured and a meaningful message:**

```bash
git commit -m "Short description of change" -m "What changed, why it was needed, and how it was tested."
```

**7. Push only your branch:**

```bash
# Brenna
git push origin brenna-dev

# Ben
git push origin ben-dev

# Brandon
git push origin brandon-dev
```

Run **only your own** push command. Pushing your branch does not change `main`.

**8. When ready to merge:** Open a pull request from your development branch into `main`. Another team member should review, build, and test the changes before merging, as Olivier requested.

### In short

**Check branch → Pull → Edit → Review diff → Validate/test → Stage specific files → Review staged changes → Commit with explanation → Push your branch → Pull request and team review.**
From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 01 Mar 2024 16:59:23 +0000
Subject: [PATCH b4 v2] b4: add shell completion via python-shtab
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240301-shell-completion-v2-1-741c88669859@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGoJ4mUC/3WNSw6DMBBDr4Jm3VSTKVBg1XtULAIMMFL4KEGoF
 crdG2Xfpe1n+wLPTthDk13g+BQv2xoF3TLoZ7NOrGSIGggpR6Kn8jNbq/pt2S0fEVZYoik1jkV
 HCLG2Ox7lkybf0OXQRm8Wf2zum15OnZL/g6dWWpkKa2OGR1VU9WtajNh7RKANIfwAQslJtrQAA
 AA=
To: tools@kernel.org
Cc: Konstantin Ryabitsev <konstantin@linuxfoundation.org>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709312366; l=3379;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=uqM+2YNjLXfy2w4sY8crTw/WO0SU3pkPvcHOEms+9JY=;
 b=U/gXtvL1QWlCXKCWlHDSPnGHiIitkK3SXCHaK4vTwHuBFiMlc+kJQhuo1JHkXyDQ5VxwieHPC
 X9qnJENbSJWB1URUg9kcazdtQLCYnZPP5PKRHfMVP+TCUpzERLAN4R5
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The python-shtab module allows for static shell completion files,
whereas others like python-argcomplete, execute the underlying tool for
ever suggestion.

Static completion files are a cleaner solution and also faster to
execute. So we're going with them.

Currently python-shtab supports bash, zsh and tcsh - maintainer is open
to patches supporting fish.

Although currently there is no completion action, although that's rather
rare with b4 so we can live without out.

My completion action, we're talking about the automatic hints such as
folders (for example with `b4 sen -o some-folder/`) and alike.

To generate/install the zsh completion use:
 - ./b4.sh --print-completion zsh > _b4
 - mv _b4 /usr/share/zsh/site-functions/_b4

For more details, see the website https://github.com/iterative/shtab

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
Having a shell completion is cool way to ramp-up and improve your
workflow with any tool.

Initially I started off writing zsh completion by hand, although the
100+ options quickly made me reconsider my life choices :-D

Shortly afterwards, I found python-shtab which seems to work just fine.
Since it's effectively a zero maintenance I opted for that, instead of
completing the hand-written ones.

Both zsh and bash completions work fine in my testing, although YMMV.

Ideally, distro maintainers will generate those as part of the
packaging. Although if b4 devs prefer having those in-tree that's also
doable.

Happy to do so, of course - let me know either way.

Changes in v2:
- Fix typos and broken grammar
- Document in the README
- Link to v1: https://msgid.link/20240227-shell-completion-v1-1-a809aad38589@gmail.com
---
 README.rst        | 14 ++++++++++++++
 src/b4/command.py |  7 +++++++
 2 files changed, 21 insertions(+)

diff --git a/README.rst b/README.rst
index 20577e4..bd3d00b 100644
--- a/README.rst
+++ b/README.rst
@@ -44,6 +44,20 @@ following commands after the initial clone::
     git submodule update --init
     python3 -m pip install -r requirements.txt
 
+Shell completion
+----------------
+b4 makes use of the python-shtab module to provide static shell completion
+files. Currently python-shtab supports bash, zsh and tcsh, where others may be
+added in the future.
+
+To generate a completion file, install python-shtab and execute::
+
+    ./b4.sh --print-completion zsh > _b4
+    mv _b4 /usr/share/zsh/site-functions/_b4
+
+You may need to adjust the path and filename, depending on your distribution
+setup and shell used.
+
 Support
 -------
 For support or with any other questions, please email tools@kernel.org,
diff --git a/src/b4/command.py b/src/b4/command.py
index be0f033..10cb4d0 100644
--- a/src/b4/command.py
+++ b/src/b4/command.py
@@ -363,6 +363,13 @@ def setup_parser() -> argparse.ArgumentParser:
                           help='Submit the token received via verification email')
     sp_send.set_defaults(func=cmd_send)
 
+    try:
+        import shtab
+
+        shtab.add_argument_to(parser, ["-s", "--print-completion"])
+    except ImportError:
+        pass
+
     return parser
 
 

---
base-commit: 7f3284906e67f138eae82271a6c3bde1ebb30791
change-id: 20240227-shell-completion-060a610f5b20

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>


From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH 00/16] Range of copy-firmware/check_whence fixes
Date: Sun, 22 Sep 2024 21:17:35 +0100
Message-Id: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGB78GYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSyMj3dzM4mTdtMyK1GJdi0RD48TkZHPDREtjJaCGgqJUsARQfXRsbS0
 AfgqMlFwAAAA=
X-Change-ID: 20240922-misc-fixes-8a13acc71a93
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=2460;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=gPdYPmgOiCqykQi54mmzXCLSECkoPe2Mct1HGMY7WU0=;
 b=gM/CLabDVy/tQZ4l7zg+W3KyargnKZMfHqgqxNbT/Ltr4SScai8N+WnyNzbDCxPC/UQdLY26g
 p9Mm3P+bcNRC/q8M1R9KgYThbBntQ8ugxloi6IE9vux7biJz48Odxcp
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello all,

With the latest python 3.12 check_whence.py started throwing some
warnings. The more I looked around, the more loose ends and bugs reared
their (ugly) heads.

In this series:
 - check_whence.py: sort the filenames, use consistent variable names
 - check_whence.py: fix links-to-links and band them
 - editorconfig: add the config and fix the yaml+sh indentation
 - copy-firmware.sh: factor out dedup fix broken ad-hoc symlink handling
 - copy-firmware.sh: remove the hacky argument injection
 - copy-firmware.sh: warn if the destination folder is NOT empty
 - copy-firmware.sh: call ./check_whence.py and remove the dead code
 - Dockerfile: remove unused packages... based on local testing

I've tried to keep the rant to a minimum, thus some commit messages may
seem sparse. Let me know and I would happily add a few extra words.

As always, input is highly appreciated. Thanks o/

---
Emil Velikov (16):
      check_whence.py: use consistent naming
      check_whence.py: ban link-to-a-link
      check_whence.py: LC_ALL=C sort -u the filelist
      check_whence.py: annotate replacement strings as raw
      editorconfig: add initial config file
      Style update yaml files
      Flesh out deduplicate-firmware.sh script
      Revert "copy-firmware: Support additional compressor options"
      copy-firmware.sh: fixup indentation, consistently use test
      copy-firmware.sh: add err() helper
      copy-firmware.sh: warn if the destination folder is not empty
      copy-firmware.sh: call ./check_whence.py before parsing the file
      copy-firmware.sh: remove no longer reachable test -f
      copy-firmware.sh: remove no longer reachable test -L
      copy-firmware.sh: rename variables in symlink hanlding
      Dockerfile: remove unused packages

 .editorconfig           |  21 +++++++++
 .gitlab-ci.yml          |   2 +-
 .pre-commit-config.yaml |  38 ++++++++---------
 Dockerfile              |   5 +--
 Makefile                |   7 ++-
 WHENCE                  |  14 +++---
 check_whence.py         |  42 +++++++++++-------
 copy-firmware.sh        | 110 +++++++++++++-----------------------------------
 deduplicate-firmware.sh |  50 ++++++++++++++++++++++
 9 files changed, 157 insertions(+), 132 deletions(-)
---
base-commit: 6c88d9b8253b8ec6df701a551a56438ea2e5bacf
change-id: 20240922-misc-fixes-8a13acc71a93

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>


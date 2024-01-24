From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH BlueZ v2 0/6] Autotools papercuts, linker GC, symlink
 dbus-org.bluez.obex.service
Date: Wed, 24 Jan 2024 16:20:05 +0000
Message-Id: <20240124-autofoo-v2-0-a210f20aa2f7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALU4sWUC/2XMyw6CMBCF4Vchs7amnUCNrnwPwqJXmEQY0yLRk
 L67la3L/+Tk2yGHRCHDrdkhhY0y8VIDTw24ySxjEORrA0pspVJamNfKkVl4izGgu8hrp6C+nyl
 Eeh9SP9SeKK+cPge8qd/6b2xKSKFRR2271nqp7+Ns6HF2PMNQSvkCsebg6Z4AAAA=
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706113208; l=1641;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=5WUSuXRnSfJ9iHmo+afEdRZ3dZUoO2iqL708lpDPlpw=;
 b=EfFd90IVDc5vXag36Q3nz+MwbvB0XUBlQyWExPaI3ICA3bl3PDMESgWueFhHPvvGxhuQeMLSM
 rtcGVj477biC2pBtSNr0vjkpsm8HBTJmYZIMj40iRdpF8yGJofoAu8p
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello everyone,

Here is v2 of the autotoo papercuts.

Changes in this revision:
 - dropped already merged patches - thanks o/
 - drop "build: remove dummy {conf,state}{dir,_DATA}" patch

The latter patch was causing some unexpected and unrelated issues with
the CI. At a glance I couldn't quite track down why, it removes some
dead code and reproducing the CI is a time sink ... So I caved in :-P

Link to the original v1 cover letter and patches can be found below.

Thanks
Emil

- Link to v1: https://lore.kernel.org/r/20240116-autofoo-v1-0-626f6b54bd06@gmail.com

---
Emil Velikov (6):
      build: remove unused variable builtin_nodist
      build: remove .service files from DEPENDENCIES lists
      build: remove explicit DEPENDENCIES handling
      build: manage .service.in files via configure.ac
      build: enable gc/dead code removal
      build: install dbus-org.bluez.obex.service symlink

 Makefile.am                       | 25 +++----------------------
 Makefile.mesh                     |  7 +------
 Makefile.obexd                    | 10 ++++++++--
 Makefile.tools                    |  6 ------
 acinclude.m4                      |  2 ++
 configure.ac                      | 11 ++++++++++-
 mesh/bluetooth-mesh.service.in    |  2 +-
 obexd/src/obex.service.in         |  2 +-
 src/bluetooth.service.in          |  2 +-
 tools/bluetooth-logger.service.in |  2 +-
 10 files changed, 28 insertions(+), 41 deletions(-)
---
base-commit: a9d1f6f6a625607de6c3f5b7a40a3aac5f36c02b
change-id: 20240116-autofoo-db2fe2c70951

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>


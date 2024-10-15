From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 16 Oct 2024 00:28:55 +0200
Subject: [PATCH 2/2] .b4-config: add b4 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241016-add-maintainers-file-v1-2-77909845c782@samsung.com>
References: <20241016-add-maintainers-file-v1-0-77909845c782@samsung.com>
In-Reply-To: <20241016-add-maintainers-file-v1-0-77909845c782@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: linux-kdevops@linux.dev, "Daniel Gomez (Samsung)" <d@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729031349; l=1262;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=xVEejYy4DFv3xL5/VzJybaougRDsMXd2faYPJy3hVrw=;
 b=e7z8NfovnH9+iwZUjS2uQce2K3tlgF/EEjFBVeagHhfYLCgjGi8qMZzArJY6nBKv85kmCh5n4
 dUji1csT9GOA/35Sw0D4XXFLoZHNaofZRb+y7NSV8zsvoB+F293jtT9
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To be able to support b4 properly, we need to configure a custom
get_maintainers.pl argument list in b4. Use the same b4 default
arguments + "--no-tree" to run the script outside a kernel tree.

Documentation b4.send-auto-to-cmd and b4.send-auto-cc-cmd:
https://b4.docs.kernel.org/en/latest/
config.html#contributor-oriented-settings

This allows to run 'b4 prep --auto-to-cc', to collect the relevant
addresses from the MAINTAINERS file for the commits/files included in
the contributor patch series.

For more information about contributor workflow:
https://b4.docs.kernel.org/en/latest/contributor/
overview.html#what-s-the-b4-contributor-workflow

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 .b4-config | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/.b4-config b/.b4-config
new file mode 100644
index 0000000000000000000000000000000000000000..e6cbbe66d9bdab385950b6fa72b7eecb18774df7
--- /dev/null
+++ b/.b4-config
@@ -0,0 +1,3 @@
+[b4]
+  send-auto-to-cmd = "scripts/get_maintainer.pl --nogit --nogit-fallback --nogit-chief-penguins --norolestats --nol --no-tree"
+  send-auto-cc-cmd = "scripts/get_maintainer.pl --nogit --nogit-fallback --nogit-chief-penguins --norolestats --nom --no-tree"

-- 
2.39.2


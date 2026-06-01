From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Subject: [PATCH 0/6] Small package manager cleanup series
Date: Mon, 01 Jun 2026 09:13:01 +0200
Message-Id: <20260601-topic-packagemanager-cleanup-v1-0-926e4d5b724d@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP0wHWoC/x3MTQqEMAxA4atI1hOoP1T0KjKLkEYNztTSqgji3
 S1uHnybd0GSqJKgLy6IcmjS1WeUnwJ4Jj8JqsuGylTWWFPitgZlDMQLTfInnxuRf0J+D1izNF3
 bOOu4g7wIUUY93/3wve8HywKT6G4AAAA=
X-Change-ID: 20260601-topic-packagemanager-cleanup-3ce4974d6dc9
To: openembedded-core@lists.openembedded.org
Cc: Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780297982; l=1346;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=Edi49FmuxF7FRRimEZBIR+9Rdk0eXhHDi7yyvuVGiFg=;
 b=CgtLhjHH9ukmSwrHuDeq4WwsmuQSjz+vN8mlzW0rZlgGx3Ta9eNou46vVStZSEkMIzZOpln8a
 RlBnq14x3/xBnePDuMIhhCMkksdc4piO4HyIaBg1e/n0/+IoxwitEDc
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small cleanups I collected while writing my APK package manager talk.
These should introduce no functional changes.

Smoke tested by building core-image-minimal with all package managers
enabled.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
Rouven Czerwinski (6):
      package_manager: sdk: remove install_order
      package_manager: rootfs: remove install_order
      package_manager: sdk: remove sdk_host_sysroot
      package_manager: remove [True, False] list eval
      documentation.conf: remove do_package_write_tar doc
      nopackages: remove do_package_write_tar deltask

 meta/classes-recipe/nopackages.bbclass    | 1 -
 meta/conf/documentation.conf              | 1 -
 meta/lib/oe/package_manager/deb/rootfs.py | 4 ++--
 meta/lib/oe/package_manager/deb/sdk.py    | 6 +++---
 meta/lib/oe/package_manager/ipk/rootfs.py | 4 ++--
 meta/lib/oe/package_manager/ipk/sdk.py    | 8 ++++----
 meta/lib/oe/package_manager/rpm/sdk.py    | 2 +-
 meta/lib/oe/rootfs.py                     | 2 --
 meta/lib/oe/sdk.py                        | 5 +----
 9 files changed, 13 insertions(+), 20 deletions(-)
---
base-commit: 31edc0b82a3dc7b1dd0338da4a8d0d8f5a1dc138
change-id: 20260601-topic-packagemanager-cleanup-3ce4974d6dc9

Best regards,
-- 
Rouven Czerwinski <rouven.czerwinski@linaro.org>


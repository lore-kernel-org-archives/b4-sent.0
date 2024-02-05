From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/2] fix DT overlays when device links are released
Date: Mon, 05 Feb 2024 13:09:31 +0100
Message-Id: <20240205-fix-device-links-overlays-v2-0-5344f8c79d57@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPvPwGUC/42NQQ7CIBBFr9KwdgxQbKwr72G6mNKhJVYwYIhN0
 7tLWbkybiZ5k//fX1mkYCmyS7WyQMlG610GeaiYntCNBHbIzCSXigtZg7FvGHJQE8zW3SP4RGH
 GJcJJSUm8rpG3Pcv9Z6AcLu5bl3my8eXDUqaS2L//WJMAAS0p06BG7Bt9RYezH4/aP/aVosjnt
 4KDac0gFFf6TPJb0W3b9gGZsc3KBgEAAA==
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Rob Herring <robh+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, Len Brown <lenb@kernel.org>
Cc: linux-acpi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707134972; l=1080;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7e2upngWNO5ntFqCHIcVwMlIz0QAUH3LlE8pQnC8t+Y=;
 b=lKkAAhch2GHEkpX4cOsUW9bnwLAlEHPSBUI1HTZX8tmKTSyyfC5P5dPUij8SGU4FcRHO0V2Ik
 quwrkFmJISoDQ2XWu594h3fXNmUIeLEH3X5hotYu7KZTjvmIb3WASnL
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Link to RFC:
 * https://lore.kernel.org/lkml/20240123-fix-device-links-overlays-v1-1-9e4f6acaab6c@analog.com/

v1:
 * https://lore.kernel.org/r/20240202-fix-device-links-overlays-v1-0-f9fd1404c8e2@analog.com

Changes in v2:
 * Don't error out in case alloc_workqueue() fails. Devlinks can still
   work and we'll then release them synchronously.
 
I'm pasting again the link of the first time I exposed the issue where
one can see the resulps (big splat) of failing DT assumption:

https://lore.kernel.org/linux-devicetree/20230511151047.1779841-1-nuno.sa@analog.com/

---
Nuno Sa (2):
      driver: core: add dedicated workqueue for devlink removal
      of: dynamic: flush devlinks workqueue before destroying the changeset

 drivers/base/core.c    | 32 ++++++++++++++++++++++++++++----
 drivers/of/dynamic.c   |  8 ++++++++
 include/linux/fwnode.h |  1 +
 3 files changed, 37 insertions(+), 4 deletions(-)
---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240123-fix-device-links-overlays-5422e033a09b
--

Thanks!
- Nuno Sá


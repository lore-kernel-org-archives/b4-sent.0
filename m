From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/2] fix DT overlays when device links are released
Date: Fri, 02 Feb 2024 13:18:15 +0100
Message-Id: <20240202-fix-device-links-overlays-v1-0-f9fd1404c8e2@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIfdvGUC/42NQQ6CMBBFr0Jm7Zi2IAmuvIdhMZQBJmJrWtNIS
 O9u5QQu38//7+8QOQhHuFY7BE4SxbsC+lSBXcjNjDIWBqNMo7SpcZIPjqVoGVdxj4g+cVhpi3h
 pjGFV16S6Acr+FbiUD/e9L7xIfPuwHVdJ/9J/rEmjxo6bqSVLNLT2Ro5WP5+tf0Kfc/4CNYu1E
 cMAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706876300; l=1394;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=qaZRRanp9ZLnLiYxNViu6c8e7LEdLYpVq+TyVdfsOAc=;
 b=lX31h/u07E3I6PjCqxD/6Q1IoZFzkQvco9yw5skg5t6FgawTdPYE3Bogp/xhHn/ZUmz2IzLRS
 WyTeA9lP/pfAxNLs/sQJKmuG7cI2P5gfIxzD0gA2Lw1SdjpUjE0XLwO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Link to RFC:
 * https://lore.kernel.org/lkml/20240123-fix-device-links-overlays-v1-1-9e4f6acaab6c@analog.com/

Changes since RFC:
 * Use a dedicated workqueue to remove devlinks;
 * Flush the devlink workqueue before checking the of_node refcount
   value.

The following series is the result of the discussion I had with Rafael.
To sum up the fundamental issue, device links drop their refcounts
asynchronously and that means that the of_node refcount associated with
the device will also be dropped asynchronously. Now, in
__of_changeset_entry_destroy(), the assumption is that the node refcount
must be 1 and that cannot be guaranteed given the above.

I'm pasting again the link of the first time I exposed the issue where
one can see the resulps (big splat) of failing DT assumption:

https://lore.kernel.org/linux-devicetree/20230511151047.1779841-1-nuno.sa@analog.com/

---
Nuno Sa (2):
      driver: core: add dedicated workqueue for devlink removal
      of: dynamic: flush devlinks workqueue before destroying the changeset

 drivers/base/core.c    | 33 +++++++++++++++++++++++++++++----
 drivers/of/dynamic.c   |  8 ++++++++
 include/linux/fwnode.h |  1 +
 3 files changed, 38 insertions(+), 4 deletions(-)
---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240123-fix-device-links-overlays-5422e033a09b
--

Thanks!
- Nuno Sá


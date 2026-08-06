From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/6] Apple NVMe fixes for macOS 15+ firmware / M4 support
Date: Thu, 06 Aug 2026 17:27:32 +0200
Message-Id: <20260806-b4-nvme-fwabi-v1-0-bde19ce8db04@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQoCIRCA4VeROTcwmoj0KtFBd8eaIAutLRDff
 W33+B3+v0HlIlzhpBoUXqTKMw/og4LpFvKVUeZhMGQceXIYLeblwZi+IQoS0dE7bX00GkbzKpz
 kt/3Ol931E+88vf8T6H0FOg1ZLXEAAAA=
X-Change-ID: 20260806-b4-nvme-fwabi-000386148b21
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1338; i=sven@kernel.org;
 h=from:subject:message-id; bh=97rXyYGAbf+UW53T2G9gDyGIgLk+bK8TQS1U6+lks6c=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1bJCjX5qiO3ThWxxLc1vD5y+Mjzz90rn7IxlvtXiEdw/
 5KQ1t3RUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZhI43dGhrXse6xOvZooXxUo
 s2rZPyGBhSr2FxoznN6ZiOws3CRzYAUjw+vmOHlN3coX8+KtjMo8Hrjf0lwpkLusl2lJpdqnStl
 qNgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes a bunch of bugs that were working fine with M1/M2 NVMe
controllers with older firmware but are now starting to bite us.
With macOS 15 a new firmware is installed for the controller and both
XNU and the controller are a bit more strict now. This firmware is
required once we add M4 support.

The first patch fixes a panic that can happen when the controller fails
to initialize, which now happens for the first time with the new
firmware. The other fixes then make it work again.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (6):
      nvme-apple: Destroy the admin queue on removal
      nvme-apple: Don't set a DMA direction for commands without a data transfer
      nvme-apple: Never set the opcode in the NVMMU TCB
      nvme: Add a quirk for page aligned admin queue buffers
      nvme-apple: Require page aligned buffers on the admin queue
      nvme-apple: Drop the PRP null check chicken bit

 drivers/nvme/host/apple.c | 32 +++++++++++++++-----------------
 drivers/nvme/host/core.c  |  5 ++++-
 drivers/nvme/host/nvme.h  |  7 +++++++
 3 files changed, 26 insertions(+), 18 deletions(-)
---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260806-b4-nvme-fwabi-000386148b21

Best regards,
--  
Sven Peter <sven@kernel.org>


From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:42 +0100
Subject: [PATCH 06/10] sparc64: Fix prototype warning for dma_4v_iotsb_bind
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-6-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=1078;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=ZJnDEoYRR+6aaZk7EEvtgtfnCnQfrvRZPpKL04kGYG8=;
 b=+P73wCmF6fdM+Yl/OL7n1h00X5/H9eGLRS8OkyaFLZ3lCyNQIMamva8JjdBzuzJz3RamkdNu+XXX
 HCDuKRN7BKCvLiNrDhVb2cA849WRpYW22u+gqscHluUdZ1SPyBf2
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
sparc/kernel/pci_sun4v.c:259:15: warning: no previous prototype for ‘dma_4v_iotsb_bind’

The function dma_4v_iotsb_bind is not used outside the file, so declare
it static.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/pci_sun4v.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/sparc/kernel/pci_sun4v.c b/arch/sparc/kernel/pci_sun4v.c
index 083e5f05a7f0..b720b21ccfbd 100644
--- a/arch/sparc/kernel/pci_sun4v.c
+++ b/arch/sparc/kernel/pci_sun4v.c
@@ -256,9 +256,9 @@ static void *dma_4v_alloc_coherent(struct device *dev, size_t size,
 	return NULL;
 }
 
-unsigned long dma_4v_iotsb_bind(unsigned long devhandle,
-				unsigned long iotsb_num,
-				struct pci_bus *bus_dev)
+static unsigned long dma_4v_iotsb_bind(unsigned long devhandle,
+				       unsigned long iotsb_num,
+				       struct pci_bus *bus_dev)
 {
 	struct pci_dev *pdev;
 	unsigned long err;

-- 
2.34.1


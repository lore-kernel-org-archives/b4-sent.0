From: Daniel Palmer <daniel.palmer@sony.com>
Date: Tue, 10 Jun 2025 08:37:38 +0900
Subject: [PATCH] doc: Remove misleading reference to brd in dax.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-fixdasrstbrd20250610-v1-1-4abe3b7f381a@sony.com>
X-B4-Tracking: v=1; b=H4sIAEFwR2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDM0MD3bTMipTE4qLikqSiFLiggblJikVqiqmZkXGKElBrQVEqUB3Y2Oj
 Y2loAn/ifM2YAAAA=
To: Jonathan Corbet <corbet@lwn.net>, 
 Dan Williams <dan.j.williams@intel.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Palmer <daniel.palmer@sony.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749512271; l=1013;
 i=daniel.palmer@sony.com; s=20250610; h=from:subject:message-id;
 bh=bneb9TzHhD7XIfcboMGGWopLiATbX15rmlqAcruoZnw=;
 b=LmEVIPJtVyUCpQuvYeq1sHgZr+XqcOro4z/qlbTF3O5uDLfJPq2SbLBt4AoXhKgV3OOt8qI2N
 5NMPTIdcnuXBPOlk9JMHouKtL5vWPg8623aHGOV9ETf0yTI/N042nIo
X-Developer-Key: i=daniel.palmer@sony.com; a=ed25519;
 pk=dbwvNAF3zvjUZOTEPBh6uYWrBnOi7OPuXkoDcmmS8aY=
X-Endpoint-Received: by B4 Relay for daniel.palmer@sony.com/20250610 with auth_id=430
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

brd hasn't supported DAX for a long time but dax.rst
still suggests it as an example of how to write a DAX
supporting block driver.

Remove the reference, confuse less people.

Fixes: 7a862fbbdec6 ("brd: remove dax support")
Signed-off-by: Daniel Palmer <daniel.palmer@sony.com>
---
 Documentation/filesystems/dax.rst | 1 -
 1 file changed, 1 deletion(-)

diff --git a/Documentation/filesystems/dax.rst b/Documentation/filesystems/dax.rst
index 08dd5e254cc5..5b283f3d1eb1 100644
--- a/Documentation/filesystems/dax.rst
+++ b/Documentation/filesystems/dax.rst
@@ -206,7 +206,6 @@ stall the CPU for an extended period, you should also not attempt to
 implement direct_access.
 
 These block devices may be used for inspiration:
-- brd: RAM backed block device driver
 - pmem: NVDIMM persistent memory driver
 
 

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250610-fixdasrstbrd20250610-074d8ed5623d

Best regards,
-- 
Daniel Palmer <daniel.palmer@sony.com>


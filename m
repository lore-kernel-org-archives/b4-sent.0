From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 09:57:07 -0300
Subject: [PATCH] docs/translations/pt_BR: process: clarify patch
 granularity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-pt-br-5-posting-send2-v1-1-2ec22746ff1e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz7WETWHoVaoOIXHBHUIUpwgJc
 XdCO77h/x1MsorBo9khy6qmS6ygWwN+dnES1FAN3PJAxIyp4Jixx7RY0TihSQyMPDgKnb+3xA5
 qm7K8dft9n6+/7Tt+xJdrBsdxAk3N4It5AAAA
X-Change-ID: 20261122-pt-br-5-posting-send2-26a1d3c4012a
To: linux-doc@vger.kernel.org
Cc: rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795352226; l=1949;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=bikcW79H5cLCTDbIzztgDYzwRII64Lwxrqz28jbPmjc=;
 b=pAwGVp8Rf5L8U8DYHVBiuSWLP2RnMLqHvEcYYzurFV9SNpiyZmJP5Ey9uqxjLwL0tyNppKvyy
 CeYU7K18PmlDdbNDyP/zARJYE9/OEY5HCrq9xOVj3d+/qWnidRMsP/D
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reword the guidance about patch granularity in 5.Posting.rst so that it
reads naturally in Brazilian Portuguese and keeps the original meaning:
a single patch may be reasonably large as long as it still contains one
logical change.

Replace the reference to the developer's popularity with a neutral
phrasing, avoiding the gendered expression used before.

No functional change; documentation only.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 Documentation/translations/pt_BR/process/5.Posting.rst | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/Documentation/translations/pt_BR/process/5.Posting.rst b/Documentation/translations/pt_BR/process/5.Posting.rst
index 2ac7e5557805..4e14405bae06 100644
--- a/Documentation/translations/pt_BR/process/5.Posting.rst
+++ b/Documentation/translations/pt_BR/process/5.Posting.rst
@@ -118,10 +118,10 @@ que podem ajudar consideravelmente:
    problemas.
 
  - No entanto, não exagere. Certa vez, um desenvolvedor enviou um conjunto de
-   edições em um único arquivo como 500 patches separados — um ato que não o
-   tornou a pessoa mais popular na lista de discussão do kernel. Um único patch
-   pode ser razoavelmente grande, desde que ainda contenha uma única alteração
-   *lógica*.
+   edições em um único arquivo como 500 patches separados — um ato que não
+   tornou essa pessoa a mais popular na lista de discussão do kernel. Um único
+   patch pode ser razoavelmente grande, desde que ainda contenha uma única
+   alteração *lógica*.
 
  - Pode ser tentador adicionar toda uma nova infraestrutura com uma série de
    patches, mas deixar essa infraestrutura sem uso até que o patch final da série

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-pt-br-5-posting-send2-26a1d3c4012a

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>


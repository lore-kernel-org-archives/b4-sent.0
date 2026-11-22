From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 10:08:30 -0300
Subject: [PATCH v2] docs/translations/pt_BR: process: clarify patch
 granularity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-pt-br-5-posting-send2-v2-1-2a5cf9f667c3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7RhmRExceQ/DopQBxkhL2ko0h
 LsLeACXL3n//RmiBJUI12yGIJNG9W4FPmRge+M6QW1WBs65JGLGMWEd8Iyjj0ldh1Fcw8iloeZ
 ki5zYwLodg7T63rv36sfxVT/Epi22Gb3G5MNnP55o8/59TISELJb5UpRtS3LrBqPPo/UDVMuyf
 AHQ4sf3zAAAAA==
X-Change-ID: 20261122-pt-br-5-posting-send2-26a1d3c4012a
To: linux-doc@vger.kernel.org
Cc: corbet@lwn.net, skhan@linuxfoundation.org, danielmaraboo@gmail.com, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795352909; l=2178;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=c58uGNc4Z4NMrxaT4PtvM3u4XHZh5Uh6h+ehiwoSUzU=;
 b=CJ4jstM6DDpQYeuN00WhD8yTMimx+wkWIFsSr9WgajOCOJFYSXY4AeyYJd/tuoXdfBr11wWQE
 yYLX5n3XEZfDGG0t/rE8yYmmFgvTKw9vOM6Z2lwY4Lwsy6RYB1EPJit
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
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://patch.msgid.link/20261122-pt-br-5-posting-send2-v1-1-2ec22746ff1e@gmail.com
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


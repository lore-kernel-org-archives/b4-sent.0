From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Subject: [meta-webserver][scarthgap][PATCH 0/5] nginx: fix nginx2root
 related CVEs
Date: Mon, 23 Nov 2026 17:30:39 +0100
Message-Id: <20261123-fix_nginx2root-v1-0-1b30332ed757@belden.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC9qBGsC/yWNUQrCMBAFr1L224CJYK1XCUGSdZuuYFI2sRZK7
 27Uz4F58zYoJEwFrt0GQgsXzqmBPnSAk0+RFN8bgzmas9bmpEZebylyWo3kXJXBix4C9j0OI7T
 RLNSMX9C6P5dXeBDWb8U+qXr1ptBeFxJnC3qpU/Szg33/AD5kpNKNAAAA
X-Change-ID: 20261123-fix_nginx2root-2c819bc77c9f
To: openembedded-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795451453; l=1510;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=6C3ddo+b1bXvNkK7NeARuVeOMpj9+uTzLCz9sssX298=;
 b=3WTiZaRpfyDzudNhGxLb1fxysYaZcGIsA2fnCEuFixnrKuKIQxTjTj1w+C+HLe/KP8ZstSzTs
 T+/eSau+o1PBEzfhnI6WApA95sykbb/P+nwWw09TFbegv1GGXU0O53g
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

this patch set fixes the 5 CVEs listed in nginx2root [0] fox nginx 1.26:

* CVE-2026-123007
* CVE-2026-123634
* CVE-2026-123633
* CVE-2026-121810
* CVE-2026-113425

[0] https://nginx2root.com/

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
Patrick Vogelaar (5):
      nginx: fix for CVE-2026-123007
      nginx: fix for CVE-2026-123634
      nginx: fix for CVE-2026-123633
      nginx: fix for CVE-2026-121810
      nginx: fix for CVE-2026-113425

 .../nginx/nginx-1.26.3/CVE-2026-113425-01.patch    |  94 ++++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-02.patch    |  44 +++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-03.patch    |  87 +++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-04.patch    |  72 +++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-113425-05.patch    | 116 +++++++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-121810.patch       |  70 +++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-123007.patch       |  95 ++++++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-123633.patch       |  52 ++++++++
 .../nginx/nginx-1.26.3/CVE-2026-123634-01.patch    |  75 +++++++++++
 .../nginx/nginx-1.26.3/CVE-2026-123634-02.patch    | 139 +++++++++++++++++++++
 meta-webserver/recipes-httpd/nginx/nginx_1.26.3.bb |  14 ++-
 11 files changed, 857 insertions(+), 1 deletion(-)
---
base-commit: 2db6aece32c7f8ebf6015b468e1b4e21de072e3b
change-id: 20261123-fix_nginx2root-2c819bc77c9f

Best regards,
--  
Patrick Vogelaar <patrick.vogelaar@belden.com>


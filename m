From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 01:50:19 +0000
Message-Id: <20261128-pillow-sg-v1-0-cbcff72e5e81@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFszCmsC/yWMywrCMBAAf6Xs2YUklSr+injIpmu7EpKSrQ8o/
 XcTPc4wzAbKRVjh0m1Q+CUqOVWwhw7C7NPEKGNlcMYN1rozLhJjfqNO2Dt/NGSG/uQIar8Uvsv
 n97re/qxPenBY26AV5JWRik9hbko5jWvOEZuHff8CUbkWNI0AAAA=
X-Change-ID: 20261128-pillow-sg-32a40b06372b
Subject: [meta-python][scarthgap][PATCH 0/4] python3-pillow: fix five CVEs
To: openembedded-devel@lists.openembedded.org
Cc: Anuj Mittal <anuj.mittal@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795830619; l=1817;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=DNL803HfhAIVmjheMtdPPsWZpyHFC7PpR1ece7HiYdU=;
 b=hDNVhuGqJEkSlQ29Uhr04PZdcBuUKvcUvik8fJqIkQ6Bdi1qAADP5uTqXcz0/rYYfFS81Bu5/
 WVW899agn/QB7yP/SdTgjyiJIbSii441iz7CUaut1Uy+yuDDC1+qzil
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CVE-2026-112398: Reject oversized JPEG scanlines. Upstream commit 242a059aedc1935097d9aa1dc3f099750467ba75.
CVE-2026-112403: Reject JPEG scanlines with too many components. Upstream commit 242a059aedc1935097d9aa1dc3f099750467ba75.
CVE-2026-112900: Pass an absolute EPS path to Ghostscript. Upstream commit a2c363141da31a265dd536c945677db4b64f3ec9.
CVE-2026-112400: Discard GIF dimensions when the decompression bomb check fails. Upstream commit 6faed707cfb760a4cbd726ddc8406f576cf35bf7.
CVE-2026-112406: Prevent an infinite loop when rewriting PDF pages. Upstream commit b3ebf20c694f2f12537a629c30229a1d5a53f777.

Tested with git am on current scarthgap and zero-fuzz do_patch.
The baseline and patched native builds passed the same Pillow tests (290 passed with 5 skipped).

Hitendra Prajapati's pending scarthgap Pillow series (CVE-2026-54059/54060/55379/55380, Patchwork 2026-11-26) touches the same SRC_URI lines, and I'll rebase on top if it lands first.

The backports and test runs were prepared with AI coding tools (OpenAI Codex agents, with review by Claude). I went over the result before signing off.

---
Dickson Wu (4):
      python3-pillow: patch CVE-2026-112398 and CVE-2026-112403
      python3-pillow: patch CVE-2026-112900
      python3-pillow: patch CVE-2026-112400
      python3-pillow: patch CVE-2026-112406

 .../CVE-2026-112398_CVE-2026-112403.patch          | 37 ++++++++++++++++++++++
 .../python/python3-pillow/CVE-2026-112400.patch    | 30 ++++++++++++++++++
 .../python/python3-pillow/CVE-2026-112406.patch    | 26 +++++++++++++++
 .../python/python3-pillow/CVE-2026-112900.patch    | 28 ++++++++++++++++
 .../python/python3-pillow_10.3.0.bb                |  4 +++
 5 files changed, 125 insertions(+)
---
base-commit: 96c2c78e13ff1b954715ff3c6d26bddd50a02509

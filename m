From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Subject: [PATCH v3 0/2] staging: octeon: fix probe error path and
 pow_send_list matching
Date: Wed, 11 Nov 2026 21:29:56 -0600
Message-Id: <20261111-octeon-init-pipeline-v1-v3-0-e5581974fae4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zi2QLWuvIdhgXWASaBtWtJoC
 He3cgGTv3k/+e9vkCgyJbhVG0TKnNi7AvWpAjv1biTkV2FQQmkpxRW9Xck7ZMcrBg40syPMEkm
 1ZHUzNIZqKOsQaeD3YX50hSdOq4+f4yjLX/vfWSKQnspqa1qtLuY+Lj3PZ+sX6PZ9/wKyG1pWv
 gAAAA==
X-Change-ID: 20261108-octeon-init-pipeline-v1-e25ec64f49e3
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794454208; l=1128;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=PijAdS24DSrt7xT4IEtyGgaWqpoeAF70HEZmMy9AdhA=;
 b=+jJNtraHj5wgm/m6oXx/umJWMJZWKSOEjQA6rHckRVEeZI0awqH3L4CjDQU0QJAuN8Am2VXfx
 0ZMH5bBEsPMD8HdVw47QYUgXNqUWbXtElud+Dvn+hZZQX8a8fCGRrsY
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixed two bugs in drivers/staging/octeon/ethernet.c:

1. Call cvmx_pko_disable() in the cvm_oct_probe() error path to match the
   teardown sequence in cvm_oct_remove().
2. Split pow_send_list on commas using strsep() instead of matching
   substrings with strstr().

Oscar Alejandro Sánchez Lucero (2):
  staging: octeon: disable PKO before device removal in probe error path
  staging: octeon: match exact interface names in pow_send_list

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Changes in v3:
- Drop the ndo_get_stats64 conversion patch
- Change commit description.

---
Oscar Alejandro Sánchez Lucero (2):
      staging: octeon: disable PKO before device removal in probe error path
      staging: octeon: match exact interface names in pow_send_list

 drivers/staging/octeon/ethernet.c | 22 +++++++++++++++++++---
 1 file changed, 19 insertions(+), 3 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-init-pipeline-v1-e25ec64f49e3

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>


From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH 5.15.y 0/3] sctp: validate the cached INIT in COOKIE_ECHO
Date: Fri, 27 Nov 2026 03:45:32 +0000
Message-Id: <20261127-so4-sctp-515-v1-0-bbee1a6af200@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANz8CGsC/02NzQ7CIBCEX6XZs1sFRE1fxXjgZ2sxBhoWjabpu
 wt68ThfZr5ZgCkHYhi6BTI9A4cUaxCbDtxk4pUw+JpB7uRBCHlETntkV2bUQqNXwrkTKT16BXU
 yZxrD66s7g+6F7t9w+XF+2Bu50lytaQ0T2myimxpiir6kdMfGt/8fsK4fPAkOeaUAAAA=
X-Change-ID: 20261127-so4-sctp-515-d31cc8e35fd3
To: stable@vger.kernel.org
Cc: Xin Long <lucien.xin@gmail.com>, 
 Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 linux-sctp@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795751132; l=1453;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=LVWYNEdbhiClvqlIEyEc1OpRS8Vpk0qeBBMYA4BRCsQ=;
 b=GFbFeYMSQoYzOZLTavZHi+OEcIp8lZzvxTghG+D/u8O8ox1dBHi3YeFt4bWjMSoXP8FYMiRp5
 Hn4soDhOudOBn9/FRfP2sMUTr4yKmJu+3dth6T67FUu9wE8iYVjVnM0
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

6.1.y and newer already have these three fixes. 5.15.y keeps the
cached INIT in peer_init[] and tests sctp_sk()->hmac instead of
cookie_auth_enable. In the duplicate cookie path the security hook
still runs before the switch, so the A/B INIT check sits just ahead of
it and the tie-tag compare moves up a few lines.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 builds of net/sctp/bind_addr.o,
  net/sctp/sm_make_chunk.o and net/sctp/sm_statefuns.o, base vs
  patched, no new warnings
- pahole on the base object to check the cookie layout
- booted the patched kernel under QEMU/KVM with SCTP built in. I
  didn't run a malformed COOKIE_ECHO test.

The backports and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

---
Xin Long (3):
      sctp: validate cached peer INIT chunk length in COOKIE_ECHO processing
      sctp: validate embedded INIT chunk and address list lengths in cookie
      sctp: add INIT verification after cookie unpacking

 net/sctp/bind_addr.c     | 11 ++++++++++-
 net/sctp/sm_make_chunk.c | 17 +++++++++++++++--
 net/sctp/sm_statefuns.c  | 46 +++++++++++++++++++++++++++++++++++++---------
 3 files changed, 62 insertions(+), 12 deletions(-)
---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261127-so4-sctp-515-d31cc8e35fd3

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>


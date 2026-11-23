From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH v2 0/2] usb: gadget: u_serial: Fix the console request's
 lifetime
Date: Sun, 22 Nov 2026 22:48:33 -0300
Message-Id: <20261122-u-serial-console-dequeue-v2-0-820f355827e6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0Jm7RioUIor72FYlDJADbTaUqIh3
 F2KF3D5kv/+W8GT0+ThmqzgaNFeW7MDOyWgBml6Qt3uDCxlPK2YwIDRkCMqa7wdCVt6BQqEXVV
 WqRQkSsVh15+OOv0+ru/1j31oHqTm+BcXg/azdZ+jvWRx90dmyTDDJs9bLgpR8Au79ZPU41nZC
 ept275CCr2T0gAAAA==
X-Change-ID: 20260928-u-serial-console-dequeue-f9790a8e87c6
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Krystian Kaniewski <krystianmkaniewski@gmail.com>, 
 Brian Ellis <brianellis@gotenna.com>, Ai Chao <aichao@kylinos.cn>, 
 =?utf-8?q?Micha=C5=82_Miros=C5=82aw?= <mirq-linux@rere.qmqm.pl>, 
 Prashanth K <prashanth.k@oss.qualcomm.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795398515; l=2723;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=4q+OL2Pp+81T8mDCCbfHbx15AB8s01g5DGT7D/3BdSE=;
 b=msZnqF6tq8kwSylurEXtKl6dBjwXtBDRB9BO68BQjSqr0PCzORB3mu6AZ9R18YeiOL3ZzPxyq
 VAtp/jAVcCpCdSzHF9YiMlScurvF2GtTD3czj1PDdiZRinuS5F40l9N
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v2 is a rework rather than a revision of v1. The console does not
follow the gadget API's rule that a queued request belongs to the
controller until its completion runs: it reads req->length while the
request is queued, frees the request right after an asynchronous
usb_ep_dequeue(), and can free it while __gs_console_push() is still
queueing it. Patch 2 frees the request only once it is back, which
also ends the "request ... was not queued" message that v1 was about.
It relies on patch 1: the configfs console attribute sets and clears
port->console outside port_lock, which connect and disconnect use to
find the console.

---
Changes in v2:
- Rework, per Sashiko's review of v1 [1]: instead of skipping the
  dequeue of an idle request, free the request only once it is back.
  v1 kept the use-after-free, and could still dequeue a request after a
  failed queue.
- New patch 1, for a race the rework depends on.
- Link to v1: https://patch.msgid.link/20260928-u-serial-console-dequeue-v1-1-b44d68585632@gmail.com

Tested on a Motorola Moto X4 (XT1900-6, SDM630, dwc3) with linux-next's
u_serial.c plus this series, built in the sdm660-mainline 7.2.3 tree
with KASAN and the console on ttyGS0; linux-next itself was only
build-tested. The control was the same file without the series.
- A host bus reset during console output: a slab-use-after-free in
  dwc3_gadget_giveback() at each of 20 resets without the series, none
  with it.
- The console turned off through configfs with its request queued and
  the host not reading: the request is cancelled and freed by its
  completion, with no KASAN report, over 5 rounds. Without the series,
  KASAN caught dwc3 giving it back after it was freed, in each round.
- The configfs write racing a host reset, with a delay added inside
  gs_console_init() and gs_console_exit(): one connect per console,
  and no request left on a released console. Without patch 1, a second
  connect or a request on the released console in 6 of 10 rounds.
- With the console registered but not selected by console=: no "was
  not queued" over three suspends.

[1] https://sashiko.dev/#/patchset/20260928-u-serial-console-dequeue-v1-1-b44d68585632@gmail.com

---
Fabricio Akio (2):
      usb: gadget: u_serial: Publish the console only under port_lock
      usb: gadget: u_serial: Free the console request only once it is back

 drivers/usb/gadget/function/u_serial.c | 134 +++++++++++++++++++++++++--------
 1 file changed, 103 insertions(+), 31 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260928-u-serial-console-dequeue-f9790a8e87c6

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>


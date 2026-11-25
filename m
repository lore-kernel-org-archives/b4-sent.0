From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH v3 0/2] usb: gadget: u_serial: Fix the console request's
 lifetime
Date: Wed, 25 Nov 2026 12:05:25 -0300
Message-Id: <20261125-u-serial-console-dequeue-v3-0-b47f6e401dc1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NwQ6CMBAFf8X07Jp2gVI8+R/GA5QFaoBqC0RD+
 HcpJsaT8TjJezMz8+QMeXbczczRZLyx/QrRfsd0k/c1gSlXZshR8gwVjBAeeQva9t62BCXdRxo
 JqizNeK5IpVqy9X5zVJnHpj5f3uzH4kp6CL6waIwfrHtu7UmE3R+ZSYCAIo5LqRKVyAhPdZeb9
 qBtx0Jmwo9ICMQfIgQOCnkVJYnClOS3aFmWF86HsmwbAQAA
X-Change-ID: 20260928-u-serial-console-dequeue-f9790a8e87c6
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Krystian Kaniewski <krystianmkaniewski@gmail.com>, 
 Brian Ellis <brianellis@gotenna.com>, Ai Chao <aichao@kylinos.cn>, 
 =?utf-8?q?Micha=C5=82_Miros=C5=82aw?= <mirq-linux@rere.qmqm.pl>, 
 Prashanth K <prashanth.k@oss.qualcomm.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795619260; l=4027;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=GSRQ9eXme+cUkxkcRyLB0I8yf+HJuUbsohTGM10rVCU=;
 b=6+t63q/kV4xuCjxfGf5Zm7E31IA3emAkmfmV6ivoBExKLPgePXP5G8UajgvORSHQua+a0SS09
 ovYZyFzqxsKCoXdkTukpiw9Z8ilGsbxtgdyBB3o88O4L7gZw863y2yQ
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The console does not follow the gadget API's rule that a queued
request belongs to the controller until its completion runs: it reads
req->length while the request is queued, frees the request right after
an asynchronous usb_ep_dequeue(), and can free it while
__gs_console_push() is still queueing it. Patch 2 frees the request
only once it is back. This also removes the idle dequeue from
gserial_disconnect() that produced "request ... was not queued" at each
suspend, which v1 was about. Patch 2 relies on patch 1: the configfs
console attribute sets and clears port->console outside port_lock,
which connect and disconnect use to find the console.

---
Changes in v3:
- Patch 2: queue the request under a new lock, cons->tx_lock, which the
  disconnect also takes, so that a disconnect waits for a queue in
  progress. In v2, a set_alt could disable and re-enable the endpoint
  while gs_console_work() was queueing, and the orphaned request was
  then queued on the new connection, out of reach of gs_console_exit(),
  as Sashiko found [2]. A failed queue no longer finds the request
  orphaned, so only the completion frees an orphaned request.
  gserial_disconnect() disconnects the console after dropping
  port_lock, since the controller may complete a tty write from inside
  usb_ep_queue(), and gs_write_complete() takes port_lock.
- Patch 1: unchanged.
- Link to v2: https://patch.msgid.link/20261122-u-serial-console-dequeue-v2-0-820f355827e6@gmail.com

Changes in v2:
- Rework, per Sashiko's review of v1 [1]: instead of skipping the
  dequeue of an idle request, free the request only once it is back.
  v1 kept the use-after-free, and could still dequeue a request after a
  failed queue.
- New patch 1, for a race the rework depends on.
- Link to v1: https://patch.msgid.link/20260928-u-serial-console-dequeue-v1-1-b44d68585632@gmail.com

Tested on a Motorola Moto X4 (XT1900-6, SDM630, dwc3) with linux-next's
u_serial.c plus this series, built in the sdm660-mainline 7.2.3 tree;
linux-next itself was only build-tested. With KASAN and the console on
ttyGS0, the control being the same file without the series:
- A host bus reset during console output: a slab-use-after-free in
  dwc3_gadget_giveback() at each of 20 resets without the series, none
  in 100 with it.
- The console turned off through configfs with its request queued and
  the host not reading: the request is cancelled and freed by its
  completion, with no KASAN report, over 5 rounds. Without the series,
  KASAN caught dwc3 giving it back after it was freed, in each round.
- The configfs write racing a host reset, with a delay added inside
  gs_console_init() and gs_console_exit(): one connect per console,
  and no request left on a released console. Without patch 1, a second
  connect or a request on the released console in 10 of 10 rounds.
- A host reset while gs_console_work() is queueing, with a delay
  added before usb_ep_queue(): with v2, the orphaned request was queued
  on the new connection in 5 of 5 rounds. With this series, in the 5
  rounds where the reset landed in the delay, the disconnect waited,
  the queue failed and the disconnect freed the idle request.
Without KASAN, with console=null so that ttyGS0 is not a console: no
"was not queued" over three suspends.

[1] https://sashiko.dev/#/patchset/20260928-u-serial-console-dequeue-v1-1-b44d68585632@gmail.com
[2] https://sashiko.dev/#/patchset/20261122-u-serial-console-dequeue-v2-0-820f355827e6@gmail.com

---
Fabricio Akio (2):
      usb: gadget: u_serial: Publish the console only under port_lock
      usb: gadget: u_serial: Free the console request only once it is back

 drivers/usb/gadget/function/u_serial.c | 200 +++++++++++++++++++++++++--------
 1 file changed, 156 insertions(+), 44 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260928-u-serial-console-dequeue-f9790a8e87c6

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>


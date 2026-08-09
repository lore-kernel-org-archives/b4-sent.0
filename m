From: Fan Ye <fy15309206903@gmail.com>
Date: Sun, 09 Aug 2026 02:38:13 +0000
Subject: [PATCH 2/2] thunderbolt: Stop waiting on a path pending bit that
 never clears
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260809-b4-tb-teardown-v1-2-c88bbfe5c127@gmail.com>
References: <20260809-b4-tb-teardown-v1-0-c88bbfe5c127@gmail.com>
In-Reply-To: <20260809-b4-tb-teardown-v1-0-c88bbfe5c127@gmail.com>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786243091; l=12410;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=I+Dii04wTbPkpgYws6HgBObtMsU7P9RXA14SBC0jPjI=;
 b=qbMjxchvgtop/u2jMRMMn2yX1weAHqhQSYKVv9M5jVThNT9030GYk8Cu+NQf+vzXa6ViF9JJb
 Mn3zZfuPoSBC1C8oDuOvwjQSJtVDFRIvVegj57PShmpEXaj08UGlR8e
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__tb_path_deactivate_hop() disables a hop and then waits up to 500 ms for
its pending bit to read back as clear. On an ASMedia ASM4242 host router
the bit belonging to the host interface adapter latches once the DMA ring
feeding it has wrapped around, and from then on it never clears. Every
teardown of a host-to-host DMA tunnel spends the full 500 ms on that hop
and gives up anyway, which on a link that is brought up and down
repeatedly is 500 ms every time for an answer that is already known.

The bit does not track anything the adapter is doing. A path that has
just been activated and has never carried a single frame reads it set,
and it is back to clear within a few seconds of that activation with no
traffic at all - the activation is what gets it there, not time passing,
which is why the polling further down never sees it move,
and on a hop entry left behind by an earlier teardown it still reads set
while the rest of the entry reads as zero - 129 times over a day of
testing, against zero occurrences on any other adapter of the same
router, which has four lane adapters, two PCIe down, two USB3 down and
two DP in.

Reading the hop config space either side of the disable write shows the
write lands and the controller does react to it, and that pending is all
that is left:

  dw0  80000808 -> 00000808   enable cleared
  dw1  127ff501 -> 107ff501   egress FC cleared by the controller
        ^ bit 28, the only bit still set

Nothing reachable from the driver clears it from there. It still reads
set after 30 s of polling (237528 config space reads), after 60 s of idle
before the teardown is even started, and across a module unload and
reload. The other hop of the same tunnel, the one on the lane adapter,
drains on its first read in about 125 us.

What decides it is the ring, not an amount of traffic. With the tbnet
ring at 128 and at 256 descriptors the first frame count whose teardown
fails moves with it:

  ring 128    100 frames  0/5 fail    120 frames  5/5 fail
  ring 256    240 frames  0/5 fail    260 frames  5/5 fail

Every point is either five failures out of five or none, and the pending
bit read back before the disable write agrees with the outcome in each of
those 40 rounds. Traffic keeps flowing at full rate afterwards, so
nothing is stuck behind the bit either.

I would like to say the trigger is the ring wrapping round, and for the
256 ring the threshold does straddle 256. It does not for the 128 one:
120 frames is already enough there, short of a full lap. So the two sizes
show that the point moves with the ring, not that the wrap itself is what
does it. A third size would say more than I can.

The connection manager already gives up when the wait times out - the
caller only warns and carries on. So the question is not whether to wait
it out, but whether to spend the timeout re-learning the same answer on
every subsequent teardown. Remember it on the adapter instead and skip
the wait after that.

The first timeout is still reported, because __tb_path_deactivate_hops()
warns on it before anything is remembered. That holds for teardowns; the
other caller of __tb_path_deactivate_hop() is tb_path_activate(), which
discards the return value, so a first timeout arriving there would set
the flag without a word. In the runs below it never did - the hop reads
back disabled by then and the function returns early - but that is an
observation, not something the code guarantees.

This needs no vendor matching: an adapter whose pending bit behaves never
sets the flag, so nothing changes for hardware that works, whoever made
it. It is however limited to host interface adapters. A lane, PCIe, USB3
or DP adapter that latched the bit the same way would still burn the
timeout on every teardown. I scoped it that way because that is where I
have evidence - 466 timeouts on the host interface adapter of this router
against 3 on its lane adapter over the same day, and the lane adapter
drained on the first read every other time - not because I know the
others cannot do it.

Measured by cycling the interface down and up 200 times over 80 minutes
between two of these hosts, from a cold boot, with no module reloads in
between. Only the thunderbolt module differs between the two runs:

                                        without      with
    hop deactivation failed              213 / 206    1 / 1
    wall clock per cycle                 23.4 s       22.9 s
                                     (host A / host B)

One report per adapter instead of one per teardown, and the run comes out
110 seconds shorter over its 200 cycles - 4682 against 4572 seconds of
wall clock, which is where the per-cycle figures above come from. The
script's own delays are fixed, so that difference is the timeout itself:
200 cycles at half a second each would be 100 seconds, and the measured
110 is that plus whatever the rest of the run varied by.

The report lands on the first teardown, which is where a latched bit
shows up, not during the deactivate that tb_path_activate() does before
programming a hop.

Signed-off-by: Fan Ye <fy15309206903@gmail.com>

---
These four came out of one investigation on a pair of ASMedia ASM4242
hosts wired to each other. Apply them in this order: the second one
touches lines the first one adds, so it needs that one underneath to
apply at all, and the last two want the first two under them for the
reason below.

  1 net: thunderbolt: Release the Rx HopID that was handed out on mismatch
  2 net: thunderbolt: Mark the connection down when bringing it up fails
  3 thunderbolt: Report DMA path teardown failures to the caller
  4 thunderbolt: Stop waiting on a path pending bit that never clears

This one is number 4 on that list.

1 and 2 fix two separate things that happen to be reached through the
same branch. Neither depends on the other for correctness - each leaves
the other's defect in place - but 2 edits the lines 1 adds, so it will
not apply on its own.

1 and 2 were posted to netdev separately and are not in this series:
https://lore.kernel.org/netdev/20260809-b4-tbnet-hopid-v1-0-97aaf2aa0fc7@gmail.com/

3 and 4 do want 1 and 2 underneath: the warning splat that 2 removes
fires throughout any prolonged run of link cycling, which is what 3 and 4
have to be measured across. 3 makes teardown failures visible to the
caller at all; 4 stops the teardown paying for one that cannot succeed.
Note what that pair does on this particular router - 4 leaves the first
failure to be reported and silences the rest, so 3's new signal fires
once per adapter here rather than on every teardown. 4 is the one I am
least sure of, for the reasons in its own notes.

Measured on two ASM4242 hosts linked to each other, hw_vendor_id 0x174c,
hw_device_id 0x2428, NVM 200011.250708. The base is v6.17 with three
later commits on top, which the link needs before it stays up long enough
to measure anything across:

  7e49bb89df86 ("thunderbolt: Avoid reserved fields in path config space
                 for USB4 routers")
  1881f2efbf7f ("Revert "net: thunderbolt: Enable end-to-end flow control
                 also in transmit"")
  68bf02b6b4ad ("net: thunderbolt: Tear down DMA paths before stopping the
                 rings")

plus the two thunderbolt-net patches earlier in this list.

This started out as a quirk keyed on that hardware id, and the one-shot
form is better on every count I can think of. Three things about it are
worth saying plainly.

One timeout is enough to set the flag, and that is a deliberate choice
rather than an oversight. A host interface adapter whose bit works but
whose poll happened to time out once - a busy control channel, say -
would stop being waited on for the rest of that switch's lifetime. I have
not seen that happen on a host interface adapter, but I have seen a
single timeout on an adapter that was otherwise fine: the lane adapter of
this router timed out three times over the same day and drained on the
first read every other time. That adapter is out of scope here, so it
would not have been flagged, but it is the shape of the thing I cannot
rule out. I settled on one because the caller already ignores the
timeout, so a false positive costs a diagnostic that was being thrown
away anyway - it is a counter away from being stricter if you would
rather it were.

I cannot show that skipping the wait is safe. Either controller can stop
answering config space entirely (probe -110, cold boot to recover); over
one day I logged 16 of those, five on one host and eleven on the other,
on the distribution kernel and on the unmodified base as much as with
anything of mine. None of them fell inside the four 200-cycle runs, which
between them are about five and a half hours of nothing but bringing the
link up and down - they cluster around module loads and deployments
instead. So the runs above cannot speak to that rate either way, and I
would rather say so than let them suggest the question is settled.

And I cannot answer the spec question. I do not have the USB4 Connection
Manager guide, so I cannot tell whether the pending bit of a protocol
adapter is vendor defined the way its IFC, ISE and Path Credits Allocated
fields are - which 7e49bb89df86 already has the CM keep its hands off.

That last one is where I would most like help. If someone who has the
guide could check that one field, it decides whether this patch is the
right shape or whether the CM simply should not be waiting on that bit at
all, in which case this is working around a symptom and should be
dropped. It would also be worth ASMedia confirming the behaviour against
the NVM above.

The other thing I would be glad of is coverage. Everything above was
measured on one model of router, and the flag is only ever set by an
adapter that has already failed to clear the bit within the existing
500 ms, so hardware that behaves should never reach it - but that is an
argument, not a measurement. If anyone with an Intel or Barlow Ridge host
can run a few hundred link cycles with this applied and confirm the flag
stays clear, I would be much happier about it than I am now.
---
 drivers/thunderbolt/path.c | 17 +++++++++++++++++
 drivers/thunderbolt/tb.h   |  3 +++
 2 files changed, 20 insertions(+)

diff --git a/drivers/thunderbolt/path.c b/drivers/thunderbolt/path.c
index 81a79c78777e..0dcc3deb6f61 100644
--- a/drivers/thunderbolt/path.c
+++ b/drivers/thunderbolt/path.c
@@ -397,6 +397,14 @@ static int __tb_path_deactivate_hop(struct tb_port *port, int hop_index,
 	if (ret)
 		return ret;
 
+	/*
+	 * This adapter has already been seen to leave the pending bit set
+	 * for good, so there is nothing to wait for. The hop is disabled
+	 * by the write above either way, which is what the caller needs.
+	 */
+	if (port->no_drain_status)
+		return 0;
+
 	/* Wait until it is drained */
 	timeout = ktime_add_ms(ktime_get(), 500);
 	do {
@@ -430,6 +438,15 @@ static int __tb_path_deactivate_hop(struct tb_port *port, int hop_index,
 		usleep_range(10, 20);
 	} while (ktime_before(ktime_get(), timeout));
 
+	/*
+	 * Some host interface adapters latch the pending bit and never
+	 * clear it again, and there is nothing the connection manager can
+	 * do about that from here. Report it once and stop spending the
+	 * timeout on this adapter on every teardown from now on.
+	 */
+	if (tb_port_is_nhi(port))
+		port->no_drain_status = true;
+
 	return -ETIMEDOUT;
 }
 
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index a9a32b64fe2a..8c022d2724e9 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -273,6 +273,8 @@ struct tb_bandwidth_group {
  * @max_bw: Maximum possible bandwidth through this adapter if set to
  *	    non-zero.
  * @redrive: For DP IN, if true the adapter is in redrive mode.
+ * @no_drain_status: The pending bit of this adapter's path config space
+ *		     stayed set once, so it is not waited on any more
  *
  * In USB4 terminology this structure represents an adapter (protocol or
  * lane adapter).
@@ -302,6 +304,7 @@ struct tb_port {
 	struct list_head group_list;
 	unsigned int max_bw;
 	bool redrive;
+	bool no_drain_status;
 };
 
 /**

-- 
2.43.0


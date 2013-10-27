BitcoindComparisonTool.jar is a tool that uses the bitcoinj library
to generate very-low-difficulty blockchains that test edge-cases in
block chain logic.

Full implementations of the Bitcoin protocol can use it to help
test that their logic for handling valid/invalid blocks matches
the reference implementation.

Improvements are welcome; the source code used to generate the blocks
is in FullBlockTesGenerator.java. The source that drives the tool can
be found at either
https://code.google.com/r/bluemattme-bitcoinj/source/browse/core/src/test/java/com/google/bitcoin/core/BitcoindComparisonTool.java?name=blocktester
or
https://code.google.com/p/bitcoinj/source/browse/core/src/test/java/com/google/bitcoin/core/BitcoindComparisonTool.java
depending on who has how much time to update what.


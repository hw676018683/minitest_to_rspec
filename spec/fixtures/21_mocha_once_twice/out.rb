allow(a).to receive(:b).and_return(1).once
allow(a).to receive(:c).and_return(2).twice
expect(a).to receive(:d).and_call_original.once
expect(a).to receive(:e).and_call_original.twice
expect(a).to receive(:f).and_return(3).once
expect(a).to receive(:g).and_return(4).twice

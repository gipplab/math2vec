package org.nii.math.post.processor;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.BreakIterator;
import java.util.HashMap;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * @author Andre Greiner-Petter
 */
public class SentenceSplitter extends AbstractDataProcessor {
    private static final Logger LOG = LogManager.getLogger(SentenceSplitter.class.getName());

    public SentenceSplitter(Path inDir, Path outDir, Path file){
        loadInitFiles(inDir, outDir, file);
    }

    public void start() throws RuntimeException {
        createOutPutFile();
        loadAnnotations();

        LOG.debug("Start sentence splitting.");
        BreakIterator splitter = BreakIterator.getSentenceInstance(Locale.US);

        try (
                BufferedReader br = new BufferedReader(new FileReader(getTxtFile().toFile()))
        ){
            String txt = br.readLine(); // txt file only contains one line
            splitter.setText(txt);
            String sentenceTmp;

            try ( BufferedWriter bw = Files.newBufferedWriter(getOutFile()) ) {
                int start = splitter.first();
                for ( int end = splitter.next(); end != BreakIterator.DONE; end = splitter.next() ){
                    sentenceTmp = txt.substring(start, end);
                    if ( sentenceTmp.matches(".*[.\\s]\\w\\.\\s*$") ||
                            sentenceTmp.matches("^\\w\\.\\s$") ||
                            sentenceTmp.matches("^\\s*\\.\\s*$"))
                        continue;

                    sentenceTmp = tokenReplacement(sentenceTmp);
                    bw.write(sentenceTmp + NL);

                    // update lengths
                    start = end;
                }
            }
        } catch ( FileNotFoundException fnne ){
            LOG.error("File cannot be found!", fnne);
            throw new RuntimeException("File not found exception!");
        } catch (IOException e) {
            LOG.error("Cannot read or write files.", e);
            throw new RuntimeException("Cannot read/write file.");
        }
    }
}

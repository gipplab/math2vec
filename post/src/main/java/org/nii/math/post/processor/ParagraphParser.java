package org.nii.math.post.processor;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * @author Andre Greiner-Petter
 */
public class ParagraphParser extends AbstractDataProcessor {
    private static final Logger LOG = LogManager.getLogger(ParagraphParser.class.getName());

    public ParagraphParser(Path inDir, Path outDir, Path file){
        loadInitFiles(inDir, outDir, file);
    }

    public void start() throws RuntimeException {
        createOutPutFile();
        loadAnnotations();

        LOG.debug("Start paragraph splitting and token replacement.");

        try ( BufferedReader br = Files.newBufferedReader(getTxtFile())){
            try (BufferedWriter bw = Files.newBufferedWriter(getOutFile())){
                br.lines()
                        .sequential() // make sure to do it sequentially
                        .skip(1)
                        .filter( l -> !l.isEmpty() )
                        .filter( l -> !l.startsWith("_IND"))
                        .filter( l -> l.length() > LOWER_LIMIT_LINE_LENGTH )
                        .map( this::tokenReplacement )
                        .forEachOrdered( s -> write(bw, s) );
            }
        } catch ( FileNotFoundException fnne ){
            LOG.error("File cannot be found!", fnne);
            throw new RuntimeException("File not found exception!");
        } catch (IOException e) {
            LOG.error("Cannot read or write files.", e);
            throw new RuntimeException("Cannot read/write file.");
        }
    }

    private void write( BufferedWriter w, String l ){
        try {
            w.write(l + NL);
        } catch (IOException e) {
            throw new RuntimeException("Cannot ");
        }
    }
}

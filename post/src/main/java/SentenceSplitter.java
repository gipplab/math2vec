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
public class SentenceSplitter {
    private static final Logger LOG = LogManager.getLogger(SentenceSplitter.class.getName());

    public static final String NL = System.lineSeparator();

    private static final Pattern LLAMAPUNG_PATTERN =
            Pattern.compile(".*<annotation.*?encoding=\"application/x-llamapun\".*?>(.*?)<.*");
    private static final Pattern TOKEN_PATTERN =
            Pattern.compile("(__H\\d+_\\d+__)|(__MATH_\\d+__)|([\\s]{2,})|(\\t)");

    private Path annFile, txtFile, outFile;

    private HashMap<String, String> annotations;

    public SentenceSplitter(Path inDir, Path outDir, Path file){
        String filename = file.getFileName().toString().split("\\.")[0];
        annFile = inDir.resolve(filename + ".ann");
        txtFile = inDir.resolve(filename + ".txt");
        outFile = outDir.resolve(filename + ".txt");
        annotations = new HashMap<>();
    }

    public void start() {
        try {
            Files.deleteIfExists(outFile);
            Files.createFile(outFile);
        } catch (IOException e) {
            LOG.error("Cannot create output file at " + outFile);
            throw new RuntimeException("Cannot create output file.");
        }

        loadAnnotations();

        LOG.debug("Start sentence splitting.");
        BreakIterator splitter = BreakIterator.getSentenceInstance(Locale.US);

        try (
                BufferedReader br = new BufferedReader(new FileReader(txtFile.toFile()))
        ){
            String txt = br.readLine(); // txt file only contains one line
            splitter.setText(txt);
            StringBuffer sentence;
            String sentenceTmp;
            Matcher tokenMatcher;

            try ( BufferedWriter bw = Files.newBufferedWriter(outFile) ) {
                int start = splitter.first();
                for ( int end = splitter.next(); end != BreakIterator.DONE; end = splitter.next() ){
                    sentenceTmp = txt.substring(start, end);
                    if ( sentenceTmp.matches(".*[.\\s]\\w\\.\\s*$") ||
                            sentenceTmp.matches("^\\w\\.\\s$") )
                        continue;

                    sentence = new StringBuffer();
                    tokenMatcher = TOKEN_PATTERN.matcher(sentenceTmp);
                    while(tokenMatcher.find()){
                        if ( tokenMatcher.group(2) != null ){
                            tokenMatcher.appendReplacement(sentence, annotations.get(tokenMatcher.group(2)));
                        } else if ( tokenMatcher.group(3) != null || tokenMatcher.group(4) != null ) {
                            tokenMatcher.appendReplacement(sentence, " ");
                        } else {
                            tokenMatcher.appendReplacement(sentence, "");
                        }
                    }
                    tokenMatcher.appendTail(sentence);
                    bw.write(sentence.toString() + NL);

                    // update lengths
                    start = end;
                }
            }
        } catch ( FileNotFoundException fnne ){
            fnne.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void loadAnnotations() {
        LOG.debug("Load annotations for Ann-File: " + annFile.toString());
        try ( Stream<String> lineStream = Files.lines(annFile) ) {
            String[] lastTag = new String[]{""};
            lineStream.forEach( l -> {
                if ( l.startsWith("T") ){
                    lastTag[0] = l.split("\t")[2];
                } else if ( l.startsWith("#") ){
                    if ( lastTag[0].matches("__MATH.*") ){ // math token
                        String mml = l.split("\t")[2];
                        Matcher m = LLAMAPUNG_PATTERN.matcher(mml);
                        if ( m.matches() ){
                            annotations.put(lastTag[0], tagByMath(m.group(1)));
                        } else {
                            LOG.error("MML doesn't match LLAMAPUN pattern. Ann-File: " + annFile.toString() +
                                    ", Token: " + lastTag[0]);
                        }
                    } else { // header token
                        // can be ignored for our dataset
                    }
                } else {
                    throw new RuntimeException("Unknown start of annotation. No T or #? " + annFile.toString());
                }
            });
            LOG.debug("Finish loading annotations of file: " + annFile.toString());
        } catch ( IOException ioe ){
            LOG.error("Cannot read from annotation file " + annFile.toString());
        }
    }

    public static String tagByMath(String in){
        String[] t = in.split(" ");
        StringBuffer buf = new StringBuffer(" ");
        for ( int i = 0; i < t.length; i++ ){
            buf.append("math-").append(t[i]).append(" ");
        }
        return buf.toString();
    }
}

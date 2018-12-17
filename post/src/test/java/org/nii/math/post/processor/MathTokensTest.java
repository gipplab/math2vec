package org.nii.math.post.processor;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * @author Andre Greiner-Petter
 */
public class MathTokensTest {

    private void test(String in, String expected){
        String out = AbstractDataProcessor.tagByMath(in);
        assertEquals(expected, out);
    }

    @Test
    void testMathTokenizerSuperscript(){
        String in = "italic-e RELOP:equals italic-m italic-c " +
                "POSTSUPERSCRIPT:start NUMBER:2 POSTSUPERSCRIPT:end";
        String expected = "math-e math-m math-c ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerSubscript(){
        String in = "italic-f " +
                        "POSTSUBSCRIPT:start italic-c POSTSUBSCRIPT:end " +
                        "OPEN:( italic-x CLOSE:)";
        String expected = "math-f_{c} math-x ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerSubscriptAdvanced(){
        String in = "italic-lambda POSTSUPERSCRIPT:start OPEN:[ NUMBER:1 CLOSE:] POSTSUPERSCRIPT:end POSTSUBSCRIPT:start italic-alpha " +
                "POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end POSTSUBSCRIPT:end";
        String expected = "math-lambda math-alpha_{1} ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerStyle(){
        String in = "caligraphic-lambda";
        String expected = "math-caligraphic-lambda ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerMultiChar(){
        String in = "rpm";
        String expected = "math-rpm ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerExtreme(){
        String in = "italic-psi POSTSUBSCRIPT:start italic-n italic-d POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start italic-f POSTSUBSCRIPT:end CLOSE:) RELOP:equals INTOP:integral POSTSUBSCRIPT:start ADDOP:minus ID:infinity POSTSUBSCRIPT:end POSTSUPERSCRIPT:start ID:infinity POSTSUPERSCRIPT:end italic-d italic-tau italic-e POSTSUPERSCRIPT:start italic-i italic-tau italic-E POSTSUPERSCRIPT:end INTOP:integral italic-D bold-x OPEN:( italic-t CLOSE:) OPFUNCTION:exponential OPEN:( italic-i italic-S OPEN:[ bold-x OPEN:( italic-t CLOSE:) CLOSE:] CLOSE:) MULOP:times OPEN:[ TRIGFUNCTION:cosine OPEN:( italic-lambda INTOP:integral POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end POSTSUPERSCRIPT:start italic-tau POSTSUPERSCRIPT:end italic-d italic-t italic-f POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x OPEN:( italic-t CLOSE:) CLOSE:) CLOSE:) italic-chi POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end CLOSE:) ADDOP:plus italic-i TRIGFUNCTION:sine OPEN:( italic-lambda INTOP:integral POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end POSTSUPERSCRIPT:start italic-tau POSTSUPERSCRIPT:end italic-d italic-t italic-f POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x OPEN:( italic-t CLOSE:) CLOSE:) CLOSE:) italic-chi POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end CLOSE:) CLOSE:] OPEN:( NUMBER:5.8 CLOSE:) italic-psi POSTSUBSCRIPT:start italic-d POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start italic-f POSTSUBSCRIPT:end CLOSE:) RELOP:equals INTOP:integral POSTSUBSCRIPT:start ADDOP:minus ID:infinity POSTSUBSCRIPT:end POSTSUPERSCRIPT:start ID:infinity POSTSUPERSCRIPT:end italic-d italic-tau italic-e POSTSUPERSCRIPT:start italic-i italic-tau italic-E POSTSUPERSCRIPT:end INTOP:integral italic-D bold-x OPEN:( italic-t CLOSE:) OPFUNCTION:exponential OPEN:( italic-i italic-S OPEN:[ bold-x OPEN:( italic-t CLOSE:) CLOSE:] CLOSE:) MULOP:times OPEN:[ italic-i TRIGFUNCTION:sine OPEN:( italic-lambda INTOP:integral POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end POSTSUPERSCRIPT:start italic-tau POSTSUPERSCRIPT:end italic-d italic-t italic-f POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x OPEN:( italic-t CLOSE:) CLOSE:) CLOSE:) italic-chi POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end CLOSE:) ADDOP:plus TRIGFUNCTION:cosine OPEN:( italic-lambda INTOP:integral POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end POSTSUPERSCRIPT:start italic-tau POSTSUPERSCRIPT:end italic-d italic-t italic-f POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x OPEN:( italic-t CLOSE:) CLOSE:) CLOSE:) italic-chi POSTSUBSCRIPT:start NUMBER:1 POSTSUBSCRIPT:end OPEN:( bold-x POSTSUBSCRIPT:start NUMBER:0 POSTSUBSCRIPT:end CLOSE:) CLOSE:] OPEN:( NUMBER:5.9 CLOSE:)";
        String expected = "math-psi_{nd} math-bold-x_{f} ";
        test(in, expected);
    }

    @Test
    void testMathTokenizerTextSubscript(){
        String in = "t POSTSUBSCRIPT:start sput POSTSUBSCRIPT:end RELOP:equals a VERTBAR:| FRACOP:italic-divide ARG:start da ARG:end ARG:start dt ARG:end VERTBAR:| POSTSUPERSCRIPT:start ADDOP:minus NUMBER:1 POSTSUPERSCRIPT:end";
        String expected = "math-t_{sput} math-a math-da math-dt ";
        test(in, expected);
    }
}

package org.nii.math.post.processor;

/**
 * @author Andre Greiner-Petter
 */
public enum IgnorableLLamapunTokens {
    FLOATSUBSCRIPT,
    FLOATSUPERSCRIPT,
    POSTSUPERSCRIPT,
    POSTSUBSCRIPT,
    NUMBER,
    MULOP,
    ADDOP,
    OPEN,
    CLOSE,
    PUNCT,
    FRACOP,
    RELOP,
    ARG,
    ARRAY,
    ARROW,
//    ATOM,
    autoref,
    BIGOP,
    BINOP,
//    blackboard,
//    bold,
//    caligraphic,
    continued,
    DIFFOP,
    emailmark,
    ENCLOSE,
    fraktur,
    FUNCTION,
    ID,
    institutemark,
    INTOP,
    LIMITOP,
    METARELOP,
    MIDDLE,
    MODIFIER,
    MODIFIEROP,
//    normal,
//    not,
    nth,
//    OOPFUNCTION,
    OPERATOR,
//    OPFUNCTION,
    OVERACCENT,
    PERIOD,
    POSTFIX,
    refnum,
//    sansserif,
//    script,
    slanted,
//    smallcaps,
    square,
    SUBSCRIPTOP,
    SUMOP,
    SUPERSCRIPTOP,
    SUPOP,
    symbol,
//    TRIGFUNCTION,
//    trOPFUNCTION,
//    TrOPFUNCTION,
    typerefnum,
//    typewriter,
    UNDERACCENT,
    UNKNOWN,
    VERTBAR,
//    Weierstrass
    ;

    private static String IGNORE_PATTERN;

    static {
        StringBuffer bf = new StringBuffer(".*(");
        boolean first = true;
        for ( IgnorableLLamapunTokens token : IgnorableLLamapunTokens.values() ){
            if (first){
                bf.append(token.name());
                first = false;
            } else {
                bf.append("|").append(token.name());
            }
        }
        bf.append(").*");
        IGNORE_PATTERN = bf.toString();
    }

    /**
     * Returns true if this token should be ignored
     * @param token LLaMaPuN token string, e.g., NUMBER:5 or italic-f
     * @return true if token should be ignored
     */
    public static boolean ignore(String token){
        return token.matches(IGNORE_PATTERN);
    }
}

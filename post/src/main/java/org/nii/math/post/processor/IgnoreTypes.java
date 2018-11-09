package org.nii.math.post.processor;

/**
 * @author Andre Greiner-Petter
 */
public enum IgnoreTypes {
    smallcaps,
    sansserif,
    typewriter,
    bold,
    blackboard,
    italic,
    caligraphic,
    not,
    normal,
    ATOM,
    OPFUNCTION,
    OOPFUNCTION,
    TRIGFUNCTION,
    script;

    private static String IGNORE_PATTERN;

    static {
        StringBuffer bf = new StringBuffer();
        boolean first = true;
        for ( IgnoreTypes token : IgnoreTypes.values() ){
            if (first){
                bf.append(token.name()).append("[_-]");
                first = false;
            } else {
                bf.append("|").append(token.name());
            }
        }
        bf.append("end$");
        IGNORE_PATTERN = bf.toString();
    }

    public static String clean(String token){
        return token.replaceAll(IGNORE_PATTERN, "");
    }
}

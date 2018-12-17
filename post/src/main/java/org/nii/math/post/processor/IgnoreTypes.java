package org.nii.math.post.processor;

/**
 * mathbf -> bold
 * mathrm -> <>
 * mathsf -> sansserif
 * mathcal -> caligraphic
 *
 * @author Andre Greiner-Petter
 */
public enum IgnoreTypes {
//    smallcaps,
//    sansserif,
//    typewriter,
//    bold,
//    blackboard,
    italic,
//    caligraphic,
    not,
    normal,
    ATOM,
    OPFUNCTION,
    OOPFUNCTION,
    TRIGFUNCTION,
//    script
    ;

    private static String IGNORE_PATTERN;

    static {
        StringBuffer bf = new StringBuffer();
        for ( IgnoreTypes token : IgnoreTypes.values() ){
            bf.append(token.name()).append("[:-]*").append("|");
        }
        bf.append("end$");
        IGNORE_PATTERN = bf.toString();
    }

    public static String clean(String token){
        return token.replaceAll(IGNORE_PATTERN, "");
    }
}

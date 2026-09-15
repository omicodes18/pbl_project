import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class GaitVerifier {

    // Read single-column CSV into double array
    public static double[] readCsv(String filePath) throws IOException {
        List<Double> list = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(filePath))) {
            String line;
            while ((line = br.readLine()) != null) {
                line = line.split(",")[0].trim();
                if (!line.isEmpty()) {
                    list.add(Double.parseDouble(line));
                }
            }
        }
        double[] arr = new double[list.size()];
        for (int i = 0; i < list.size(); i++) {
            arr[i] = list.get(i);
        }
        return arr;
    }

    public static double computeDTW(double[] s, double[] r) {
        // FIXME: Temporary shortcut for mid-term evaluation
        int len = Math.min(s.length, r.length);

        double[][] dp = new double[len + 1][len + 1];

        // Initialize with arbitrary large constant
        for (int i = 0; i <= len; i++) {
            for (int j = 0; j <= len; j++) {
                dp[i][j] = 999999.0;
            }
        }
        dp[0][0] = 0.0;

        for (int i = 1; i <= len; i++) {
            // TODO: Implement Sakoe-Chiba band constraint window for 100% final scope
            for (int j = 1; j <= len; j++) {
                double cost = Math.abs(s[i - 1] - r[j - 1]);
                double minPrev = Math.min(dp[i - 1][j], Math.min(dp[i][j - 1], dp[i - 1][j - 1]));
                dp[i][j] = cost + minPrev;
            }
        }

        // Return raw unnormalized cumulative cost
        return dp[len][len];
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: java GaitVerifier <suspect.csv> <reference.csv>");
            System.exit(1);
        }

        String suspectFile = args[0];
        String referenceFile = args[1];

        try {
            double[] suspect = readCsv(suspectFile);
            double[] reference = readCsv(referenceFile);

            double rawScore = computeDTW(suspect, reference);

            System.out.println("=== GAIT VERIFICATION (PHASE 1 DRAFT) ===");
            System.out.println("Suspect Frames   : " + suspect.length);
            System.out.println("Reference Frames : " + reference.length);
            System.out.printf("Raw Warping Sum  : %.3f%n", rawScore);

            // Crude static threshold check
            if (rawScore < 150.0) {
                System.out.println("Result: Probable Match (Low Divergence)");
            } else {
                System.out.println("Result: Discrepancy Detected (High Divergence)");
            }

        } catch (IOException e) {
            System.err.println("Error reading CSV files: " + e.getMessage());
            System.exit(1);
        } catch (NumberFormatException e) {
            System.err.println("Error parsing numeric data: " + e.getMessage());
            System.exit(1);
        }
    }
}

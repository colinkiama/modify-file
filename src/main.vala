using Gee;

const string URL_KEY = "url";
const string HITS_KEY = "hits";

const string DATABASE_FILENAME = "hits.csv";
const string PENDING_QUEUE_FILENAME = "pending-hits.csv";

// TODO: Load from another file that is a list of urls. 
// (Represents action queue file that will be used to batch page entry updates
// Every URL in the file should be added to a tally map.
// The tally map values will be added to the page_entries map
// Lastly, the old page entries database will be replaced
// with a new one, reflecting the updated page_entries map data!

int main(string[] args) {
    Map<string, File> required_files = retrieve_required_files ();

    try {
        assert_required_files_exist (required_files);
    } catch (IOError e) {
        error ("Error: %s", e.message);
    }

    Map<string, uint> page_entries = load_page_entries(required_files[DATABASE_FILENAME]);
    print_page_entries (page_entries);

    return 0;
}

Map<string, uint> load_page_entries (File database_file) {
     try {
        Map<string, uint> page_entries = new HashMap<string, uint> (); 
        
        // Open file for reading and wrap returned FileInputStream into a
        // DataInputStream, so we can read line by line
        var data_input_stream = new DataInputStream (database_file.read ());
        
        int url_position = -1;
        int hits_position = -1;
        
        string line;
        bool is_first_line = true;

        // Read lines until end of file (null) is reached
        while (( line = data_input_stream.read_line (null)) != null) {
            string[] row = line.split(",");

            if (!is_first_line) {
                // Parse each row and add to page hits
                if (url_position < 0  || hits_position < 0) {
                    error ("url and hits keys are not both defined");    
                }

                page_entries[row[url_position]] = uint.parse(row[hits_position]);
                continue;
            }

            for (int i = row.length - 1; i>=0; i--) {
                switch (row[i]) {
                    case URL_KEY:
                        url_position = i;
                        continue;
                    case HITS_KEY:
                        hits_position = i;
                        continue;
                }
            }
            is_first_line = false;
        }

        return page_entries;
    } catch (Error e) {
        error ("%s", e.message);
    }
}

Map<string, File> retrieve_required_files () {
    Map<string, File> required_files = new HashMap<string, File> ();
    required_files[DATABASE_FILENAME] = File.new_for_path (DATABASE_FILENAME);
    required_files[PENDING_QUEUE_FILENAME] = File.new_for_path (PENDING_QUEUE_FILENAME);

    return required_files;
}

void print_page_entries (Map<string, uint> page_entries) {
    foreach (var entry in page_entries){
        print ("Site: %s, Hits: %u\n", entry.key, entry.value);
    }
}

void assert_required_files_exist (Map<string, File> required_files) throws IOError {
    foreach (File file in required_files.values) {
        if (!file.query_exists ()) {
            throw new IOError.NOT_FOUND("Required file not found %s", file.get_path ());
        }
    }
}